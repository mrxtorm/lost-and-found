import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/feedback_model.dart';
import '../models/item_model.dart';
import '../models/notification_model.dart';
import '../models/report_model.dart';
import '../models/suspended_user.dart';

/// Admin-only moderation.
///
/// A user is an admin when admins/{uid} exists. That collection can only be
/// edited from the Firebase Console (firestore.rules deny every client
/// write), so users cannot promote themselves. Every write below is also
/// checked server-side by isAdmin() in firestore.rules - hiding the UI is
/// only a convenience.
class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const suspensionDays = 7;

  /// Written to bannedUntil to end a suspension. A fixed time in the past
  /// (not "now") so the user leaves the "bannedUntil > now" query at once,
  /// even before the server confirms and regardless of clock differences.
  static final Timestamp _notSuspended = Timestamp.fromMillisecondsSinceEpoch(
    0,
  );

  CollectionReference<Map<String, dynamic>> get _reports =>
      _firestore.collection('reports');

  CollectionReference<Map<String, dynamic>> get _log =>
      _firestore.collection('moderationLog');

  /// True if the signed-in user has an admins/{uid} document.
  Future<bool> isCurrentUserAdmin() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    try {
      final doc = await _firestore
          .collection('admins')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 8));
      return doc.exists;
    } catch (_) {
      return false;
    }
  }

  /// Live version of [isCurrentUserAdmin]: updates when admins/{uid} is
  /// created or deleted in the Firebase Console. Errors count as "no".
  Stream<bool> watchIsCurrentUserAdmin() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(false);
    return _firestore
        .collection('admins')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists)
        .transform(
          StreamTransformer<bool, bool>.fromHandlers(
            handleError: (_, _, sink) => sink.add(false),
          ),
        );
  }

  /// Pending reports, newest first (sorted here to avoid needing a
  /// composite index).
  Stream<List<ReportModel>> streamPendingReports() {
    return _reports.where('status', isEqualTo: 'pending').snapshots().map((
      snapshot,
    ) {
      final reports = snapshot.docs.map(ReportModel.fromDoc).toList();
      reports.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.now();
        final bDate = b.createdAt ?? DateTime.now();
        return bDate.compareTo(aDate);
      });
      return reports;
    });
  }

  /// Number of distinct posts/messages waiting for review (several reports
  /// about the same content count once, matching the dashboard cards).
  Stream<int> streamPendingTargetCount() {
    return streamPendingReports().map(
      (reports) =>
          reports.map((r) => '${r.targetType}_${r.targetId}').toSet().length,
    );
  }

  /// Most recent admin decisions.
  Stream<List<ModerationLogEntry>> streamHistory({int limit = 100}) {
    return _log
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(ModerationLogEntry.fromDoc).toList());
  }

  /// Most recent post-return feedback from users.
  Stream<List<FeedbackEntry>> streamFeedback({int limit = 200}) {
    return _firestore
        .collection('feedback')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(FeedbackEntry.fromDoc).toList());
  }

  /// The other participant's feedback for the same return, or null if they
  /// haven't left any. Feedback ids are {returnId}_{authorUid}.
  Future<FeedbackEntry?> fetchCounterpartFeedback(FeedbackEntry entry) async {
    if (entry.returnId.isEmpty || entry.otherUserId.isEmpty) return null;
    final doc = await _firestore
        .collection('feedback')
        .doc('${entry.returnId}_${entry.otherUserId}')
        .get();
    return doc.exists ? FeedbackEntry.fromDoc(doc) : null;
  }

  /// The reported post, or null if it no longer exists.
  Future<ItemModel?> fetchItem(String itemId) async {
    final doc = await _firestore.collection('items').doc(itemId).get();
    return doc.exists ? ItemModel.fromDoc(doc) : null;
  }

  /// Applies one decision to every pending report about the same post or
  /// message ([reports] must all share the same target).
  ///
  /// - dismiss: reports are closed, content stays.
  /// - remove: the post is deleted / the message text is replaced.
  /// - removeAndSuspend: as remove, plus a [suspensionDays]-day posting
  ///   ban using the existing users/{uid}.bannedUntil rule.
  ///
  /// Every decision is written to moderationLog in the same batch, so the
  /// history can't miss an action.
  Future<void> resolve({
    required List<ReportModel> reports,
    required String action,
    String note = '',
  }) async {
    final admin = _auth.currentUser;
    if (admin == null) throw Exception('You must be signed in.');
    if (reports.isEmpty) return;

    final target = reports.first;
    final removing = action != ModerationAction.dismiss;
    final batch = _firestore.batch();
    final backupRef = _backupRef(target.targetType, target.targetId);

    if (removing) {
      // A copy of the removed content is kept in removedContent/ so the
      // decision can be undone. Rules check the copy matches the real
      // post/message, so an undo can only ever restore genuine content.
      if (target.isItem) {
        // Deleting a post that is already gone is harmless, but skip it so
        // the log reflects what actually happened.
        final itemRef = _firestore.collection('items').doc(target.targetId);
        final itemDoc = await itemRef.get();
        if (itemDoc.exists) {
          batch.set(backupRef, {
            ..._backupBase(target, admin.uid),
            'item': itemDoc.data(),
          });
          batch.delete(itemRef);
        }
      } else {
        // Admins cannot read messages, so whether it still exists (e.g.
        // the conversation was deleted after a claim was approved) is only
        // known when the batch commits - see the catch below.
        batch.set(backupRef, {
          ..._backupBase(target, admin.uid),
          'text': target.contentPreview,
        });
        batch.update(_messageRef(target.conversationId, target.targetId), {
          'text': ReportTarget.removedMessageText,
          'removedByAdmin': true,
        });
      }

      if (action == ModerationAction.removeAndSuspend) {
        batch.set(
          _firestore.collection('users').doc(target.reportedUserId),
          {
            'offenseCount': FieldValue.increment(1),
            'bannedUntil': Timestamp.fromDate(
              DateTime.now().add(const Duration(days: suspensionDays)),
            ),
            // Lets the Suspended tab show who this is.
            'displayName': target.reportedUserName,
            'suspendedBy': admin.uid,
            'suspendedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      batch.set(
        _firestore.collection('notifications').doc(),
        NotificationModel(
          id: '',
          recipientId: target.reportedUserId,
          type: NotificationType.moderationRemoved,
          title: target.isItem ? 'Post removed' : 'Message removed',
          message: _noticeFor(target, action),
          isRead: false,
        ).toMap(),
      );
    }

    for (final report in reports) {
      batch.update(_reports.doc(report.id), {
        'status': removing ? 'actioned' : 'dismissed',
        'reviewedBy': admin.uid,
        'reviewedAt': FieldValue.serverTimestamp(),
        'resolution': action,
      });
    }

    batch.set(_log.doc(), {
      'adminId': admin.uid,
      'adminEmail': admin.email ?? '',
      'action': action,
      'targetType': target.targetType,
      'targetId': target.targetId,
      'reportedUserId': target.reportedUserId,
      'reportedUserName': target.reportedUserName,
      'contentPreview': target.contentPreview,
      'reasons': reports.map((r) => r.reason).toSet().toList(),
      'reportCount': reports.length,
      'reportIds': reports.map((r) => r.id).toList(),
      'note': note.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    try {
      await batch.commit();
    } on FirebaseException catch (e) {
      if (removing && !target.isItem && e.code == 'permission-denied') {
        throw Exception(
          'The message could not be removed. It may already have been '
          'deleted along with its conversation. You can dismiss the '
          'report instead.',
        );
      }
      rethrow;
    }
  }

  /// Reverts [entry]:
  /// - its reports go back to the pending queue,
  /// - a removed post is recreated (same id, so claims/chats reconnect) or
  ///   a removed message gets its original text back,
  /// - a suspension is lifted,
  /// - the user is told their content was restored.
  ///
  /// Logged as moderationLog/undo_{entry.id}. That id is deterministic and
  /// the log is create-only, so a decision can only be undone once.
  Future<void> undo(ModerationLogEntry entry, {String note = ''}) async {
    final admin = _auth.currentUser;
    if (admin == null) throw Exception('You must be signed in.');
    if (entry.isUndo) throw Exception('An undo cannot be undone.');

    final isItem = entry.targetType == ReportTarget.item;
    final what = isItem ? 'post' : 'message';
    final batch = _firestore.batch();

    if (ModerationAction.isRemoval(entry.action)) {
      final backupRef = _backupRef(entry.targetType, entry.targetId);
      final backup = await backupRef.get();
      if (!backup.exists) {
        throw Exception(
          'This $what cannot be restored: no saved copy exists. It may '
          'already have been restored, or was removed before undo was '
          'available.',
        );
      }
      final data = backup.data()!;

      if (isItem) {
        final itemRef = _firestore.collection('items').doc(entry.targetId);
        if (!(await itemRef.get()).exists) {
          batch.set(itemRef, Map<String, dynamic>.from(data['item'] as Map));
        }
      } else {
        batch.update(
          _messageRef(data['conversationId'] as String, entry.targetId),
          {'text': data['text'], 'removedByAdmin': false},
        );
      }
      batch.delete(backupRef);

      if (entry.action == ModerationAction.removeAndSuspend) {
        // Ends the ban now. (If the user was suspended again by a later
        // decision, this lifts that too - re-suspend them if needed.)
        batch.set(
          _firestore.collection('users').doc(entry.reportedUserId),
          {
            'offenseCount': FieldValue.increment(-1),
            'bannedUntil': _notSuspended,
          },
          SetOptions(merge: true),
        );
      }

      batch.set(
        _firestore.collection('notifications').doc(),
        NotificationModel(
          id: '',
          recipientId: entry.reportedUserId,
          type: NotificationType.moderationRestored,
          title: isItem ? 'Post restored' : 'Message restored',
          message:
              '${isItem ? 'Your post "${entry.contentPreview}"' : 'A message you sent'}'
              ' was reviewed again and has been restored.'
              '${entry.action == ModerationAction.removeAndSuspend ? ' Your posting suspension was lifted.' : ''}',
          isRead: false,
        ).toMap(),
      );
    }

    // Back into the review queue.
    for (final reportId in entry.reportIds) {
      batch.update(_reports.doc(reportId), {
        'status': 'pending',
        'reviewedBy': admin.uid,
        'reviewedAt': FieldValue.serverTimestamp(),
        'resolution': 'undone',
      });
    }

    batch.set(_log.doc('undo_${entry.id}'), {
      'adminId': admin.uid,
      'adminEmail': admin.email ?? '',
      'action': ModerationAction.undo,
      'undoOf': entry.id,
      'targetType': entry.targetType,
      'targetId': entry.targetId,
      'reportedUserId': entry.reportedUserId,
      'reportedUserName': entry.reportedUserName,
      'contentPreview': entry.contentPreview,
      'reasons': entry.reasons,
      'reportCount': entry.reportCount,
      'reportIds': entry.reportIds,
      'note': note.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    try {
      await batch.commit();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Could not undo this decision. It may already have been undone, '
          'or the ${isItem ? 'post' : 'conversation'} no longer exists.',
        );
      }
      rethrow;
    }
  }

  /// Users with an active posting suspension, ending soonest first.
  Stream<List<SuspendedUser>> streamSuspendedUsers() {
    return _firestore
        .collection('users')
        .where('bannedUntil', isGreaterThan: Timestamp.now())
        .snapshots()
        .map((snapshot) {
          // The query's cutoff is fixed when the listener starts, so this
          // can include suspensions that have since expired. Screens filter
          // with SuspendedUser.isActive at build time (and re-build on a
          // timer) so they drop off the moment they end.
          final users = snapshot.docs
              .map(SuspendedUser.fromDoc)
              .whereType<SuspendedUser>()
              .toList();
          users.sort((a, b) => a.bannedUntil.compareTo(b.bannedUntil));
          return users;
        });
  }

  /// Ends [user]'s suspension now. The offense count is kept (lifting a
  /// ban early isn't the same as undoing the decision behind it). Logged
  /// in the history and the user is notified.
  Future<void> liftSuspension(
    SuspendedUser user, {
    required String displayName,
    String note = '',
  }) async {
    final admin = _auth.currentUser;
    if (admin == null) throw Exception('You must be signed in.');

    final batch = _firestore.batch();
    batch.update(_firestore.collection('users').doc(user.uid), {
      'bannedUntil': _notSuspended,
    });
    batch.set(
      _firestore.collection('notifications').doc(),
      NotificationModel(
        id: '',
        recipientId: user.uid,
        type: NotificationType.moderationRestored,
        title: 'Suspension lifted',
        message:
            'An admin lifted your posting suspension. You can report '
            'and edit items again.',
        isRead: false,
      ).toMap(),
    );
    batch.set(_log.doc(), {
      'adminId': admin.uid,
      'adminEmail': admin.email ?? '',
      'action': ModerationAction.unban,
      'targetType': 'user',
      'targetId': user.uid,
      'reportedUserId': user.uid,
      'reportedUserName': displayName,
      'contentPreview':
          'Posting suspension lifted early (was until '
          '${user.bannedUntil.month}/${user.bannedUntil.day}/'
          '${user.bannedUntil.year})',
      'reasons': <String>[],
      'reportCount': 0,
      'reportIds': <String>[],
      'note': note.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  DocumentReference<Map<String, dynamic>> _backupRef(
    String targetType,
    String targetId,
  ) => _firestore.collection('removedContent').doc('${targetType}_$targetId');

  DocumentReference<Map<String, dynamic>> _messageRef(
    String conversationId,
    String messageId,
  ) => _firestore
      .collection('conversations')
      .doc(conversationId)
      .collection('messages')
      .doc(messageId);

  Map<String, dynamic> _backupBase(ReportModel target, String adminId) => {
    'targetType': target.targetType,
    'targetId': target.targetId,
    'conversationId': target.conversationId,
    'removedBy': adminId,
    'removedAt': FieldValue.serverTimestamp(),
  };

  String _noticeFor(ReportModel target, String action) {
    final what = target.isItem
        ? 'Your post "${target.contentPreview}" was removed'
        : 'One of your messages was removed';
    final suspended = action == ModerationAction.removeAndSuspend
        ? ' You cannot create or edit posts for $suspensionDays days.'
        : '';
    return '$what by an admin for breaking the community rules.$suspended';
  }
}
