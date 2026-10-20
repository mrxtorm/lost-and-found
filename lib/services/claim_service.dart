import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/claim_model.dart';
import '../models/item_model.dart';
import '../models/notification_model.dart';
import 'notification_service.dart';
import 'chat_service.dart';
import 'feedback_service.dart';

/// Handles claim requests separately from the item's Lost/Found type.
///
/// IMPORTANT:
/// - items/{itemId}.status stays Lost/Found while a claim is pending.
/// - claims/{itemId}_{claimantId}.status contains Pending/Approved/Rejected.
/// - Only the item owner and the claimant can read the claim document.
class ClaimService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();
  final ChatService _chatService = ChatService();

  CollectionReference<Map<String, dynamic>> get _claims =>
      _firestore.collection('claims');

  CollectionReference<Map<String, dynamic>> get _items =>
      _firestore.collection('items');

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('You must be signed in.');
    }
    return user.uid;
  }

  /// Returns the claim belonging to [itemId] when the current user is the
  /// claimant or the owner. Firestore rules hide it from everybody else.
  Stream<ClaimModel?> streamClaimForItem(String itemId) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _claims
        .where('itemId', isEqualTo: itemId)
        .where('claimantId', isEqualTo: uid)
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs.isEmpty
            ? null
            : ClaimModel.fromDoc(snap.docs.first));
  }

  Stream<ClaimModel?> streamClaimForConversation(
    String itemId,
    String otherUserId,
  ) {
    final uid = _auth.currentUser?.uid;
    if (uid == null || otherUserId.isEmpty) return const Stream.empty();

    return _claims
        .where('itemId', isEqualTo: itemId)
        .where('claimantId', whereIn: [uid, otherUserId])
        .snapshots()
        .map((snap) {
          for (final doc in snap.docs) {
            final claim = ClaimModel.fromDoc(doc);
            if ((claim.claimantId == uid && claim.ownerId == otherUserId) ||
                (claim.claimantId == otherUserId && claim.ownerId == uid)) {
              return claim;
            }
          }
          return null;
        });
  }

  Stream<List<ClaimModel>> streamClaimsForClaimant(String claimantId) {
    return _claims
        .where('claimantId', isEqualTo: claimantId)
        .snapshots()
        .map((snap) => snap.docs.map(ClaimModel.fromDoc).toList());
  }

  /// One-time check used by the Claim Item button. This also works after an
  /// app restart because the claimant is allowed to read their own claim.
  Future<bool> hasPendingClaimForCurrentUser(String itemId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final snap = await _claims
          .where('itemId', isEqualTo: itemId)
          .where('claimantId', isEqualTo: user.uid)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return false;
      final data = snap.docs.first.data();
      return (data['status'] as String? ?? '').toLowerCase() == 'pending';
    } catch (_) {
      return false;
    }
  }

  /// Submits a claim without changing the public Lost/Found type of the item.
  Future<void> submitClaim({
    required ItemModel item,
    required String answer,
    required String additionalDetails,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('You must be signed in to submit a claim.');
    }

    if (item.ownerId == user.uid) {
      throw Exception('You cannot claim your own item.');
    }

    if (item.status.toLowerCase() != 'found' &&
        item.status.toLowerCase() != 'pending') {
      throw Exception('Only Found items can be claimed.');
    }

    final claimantName =
        (user.displayName != null && user.displayName!.trim().isNotEmpty)
            ? user.displayName!.trim()
            : (user.email ?? 'Unknown User');

    final claimId = '${item.id}_${user.uid}';
    final claimRef = _claims.doc(claimId);
    final existing = await claimRef.get();

    // A claim doc that already exists at this point can only be a rejected
    // one (pending/approved throw below), so this is a resend.
    final isResend = existing.exists;

    if (existing.exists) {
      final existingData = existing.data() ?? <String, dynamic>{};
      final existingClaimantId = existingData['claimantId'] as String? ?? '';
      final existingStatus =
          (existingData['status'] as String? ?? '').toLowerCase();

      if (existingClaimantId != user.uid) {
        throw Exception('This claim belongs to another user.');
      }

      if (existingStatus == 'pending') {
        throw Exception('You already submitted a claim for this item.');
      }

      if (existingStatus == 'approved') {
        throw Exception('This claim has already been approved.');
      }

      // A rejected claimant may submit again with updated verification
      // answers. The same deterministic id still prevents duplicate active
      // claims for this user/item pair.
      await claimRef.update({
        'answer': answer.trim(),
        'additionalDetails': additionalDetails.trim(),
        'status': 'Pending',
      });
    } else {
      final claim = ClaimModel(
        id: claimRef.id,
        itemId: item.id,
        itemTitle: item.title,
        itemImageUrl: item.imageUrl,
        claimantId: user.uid,
        claimantName: claimantName,
        ownerId: item.ownerId,
        answer: answer.trim(),
        additionalDetails: additionalDetails.trim(),
        status: 'Pending',
      );

      // Keep the item's public status unchanged. The claim is private to the
      // two involved users through Firestore security rules.
      await claimRef.set(claim.toMap());
    }

    // Put the claim request into the same conversation used for follow-up
    // discussion. The answers themselves are displayed in the private claim
    // panel inside that conversation.
    try {
      final conversationId = await _chatService.getOrCreateConversation(
        postId: item.id,
        itemName: item.title,
        itemImageUrl: item.imageUrl,
        itemType: 'Found',
        otherUserId: item.ownerId,
        otherUserName: item.username,
      );

      await _chatService.sendMessageWithId(
        // A resend needs a fresh id; the original claim message already
        // uses 'claim_<itemId>' and Firestore rules don't allow overwriting it.
        messageId: isResend
            ? 'claim_${item.id}_${DateTime.now().millisecondsSinceEpoch}'
            : 'claim_${item.id}',
        conversationId: conversationId,
        senderId: user.uid,
        senderName: claimantName,
        text: isResend
            ? 'Claim request resent for "${item.title}".'
            : 'Claim request submitted for "${item.title}".',
        timestamp: DateTime.now(),
      );
    } catch (_) {
      // The claim remains valid even if conversation creation temporarily
      // fails. The next online sync/retry can still be used to recover it.
    }

    await _notificationService.createNotification(
      recipientId: item.ownerId,
      type: NotificationType.claimReceived,
      title: isResend ? 'Claim Request Resent' : 'Claim Request Received',
      message: isResend
          ? '$claimantName resent their claim for "${item.title}".'
          : '$claimantName submitted a claim for "${item.title}".',
      relatedItemId: item.id,
      relatedClaimId: claimRef.id,
    );
  }

  Stream<List<ClaimModel>> streamClaimsForOwner(String ownerId) {
    return _claims
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ClaimModel.fromDoc).toList());
  }

  /// The item owner is the only person who can approve/reject a claim.
  /// Approved claims are cleaned up immediately for privacy.
  Future<void> updateClaimStatus(String claimId, String status) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('You must be signed in.');
    }

    final normalized = status.trim().toLowerCase();
    if (normalized != 'approved' && normalized != 'rejected') {
      throw Exception('Invalid claim status.');
    }

    final claimRef = _claims.doc(claimId);
    final claimSnap = await claimRef.get();
    if (!claimSnap.exists) {
      throw Exception('Claim no longer exists.');
    }

    final data = claimSnap.data()!;
    final ownerId = data['ownerId'] as String? ?? '';
    final claimantId = data['claimantId'] as String? ?? '';
    final itemId = data['itemId'] as String? ?? claimId;
    final itemTitle = data['itemTitle'] as String? ?? 'the item';

    if (ownerId != user.uid) {
      throw Exception('Only the finder can accept or reject this claim.');
    }

    if (normalized == 'rejected') {
      await claimRef.update({'status': 'Rejected'});

      await _notificationService.createNotification(
        recipientId: claimantId,
        type: NotificationType.claimRejected,
        title: 'Claim Rejected',
        message:
            'Your claim for "$itemTitle" was rejected. You can continue discussing the item.',
        relatedItemId: itemId,
        relatedClaimId: claimId,
      );
      return;
    }

    await claimRef.update({'status': 'Approved'});

    // The post isn't deleted yet: it moves to the finder's archive for
    // ItemModel.archiveDays, where the claim can still be undone if the
    // handover falls through. The claim and chat are kept until then too.
    await _items.doc(itemId).update(_claimedFields(
      from: 'Found',
      claimedBy: claimantId,
      claimedByName: data['claimantName'] as String? ?? '',
    ));

    // Minimal record that lets both participants leave optional feedback.
    try {
      await FeedbackService().recordCompletedReturn(
        claimId: claimId,
        itemId: itemId,
        itemTitle: itemTitle,
        ownerId: ownerId,
        claimantId: claimantId,
      );
    } catch (_) {}

    try {
      await _notificationService.createNotification(
        recipientId: claimantId,
        type: NotificationType.claimApproved,
        title: 'Claim Approved',
        message: 'Your claim for "$itemTitle" was approved.',
        relatedItemId: itemId,
        relatedClaimId: claimId,
      );
    } catch (_) {}
  }

  // ============================================================
  // CLAIMED POSTS (archive)
  // ============================================================

  Map<String, dynamic> _claimedFields({
    required String from,
    required String claimedBy,
    required String claimedByName,
  }) {
    return {
      'status': 'Claimed',
      'claimedFrom': from,
      'claimedBy': claimedBy,
      'claimedByName': claimedByName,
      'claimedAt': FieldValue.serverTimestamp(),
    };
  }

  /// The id of the completed-return record for a Lost post returned by
  /// [finderId]. (Found posts use the claim id instead.)
  static String lostReturnId(String itemId, String finderId) =>
      '${itemId}_$finderId';

  /// The owner of a Lost post confirms they got it back. [finderId] is the
  /// person who returned it ('' if the owner doesn't name anyone, e.g. from
  /// My Posts). Returns the completed-return id for the feedback prompt, or
  /// null when no finder was named.
  Future<String?> markLostItemReturned(
    ItemModel item, {
    String finderId = '',
    String finderName = '',
  }) async {
    final uid = _uid;
    if (item.ownerId != uid) {
      throw Exception('Only the person who posted this can mark it claimed.');
    }
    if (item.status.toLowerCase() != 'lost') {
      throw Exception('Only lost posts can be marked as claimed here.');
    }

    await _items.doc(item.id).update(_claimedFields(
      from: 'Lost',
      claimedBy: finderId,
      claimedByName: finderName,
    ));

    if (finderId.isEmpty) return null;

    final returnId = lostReturnId(item.id, finderId);
    // On a Lost post the roles flip: the finder is the other person, the
    // post owner is the one who got their item back.
    try {
      await FeedbackService().recordCompletedReturn(
        claimId: returnId,
        itemId: item.id,
        itemTitle: item.title,
        ownerId: finderId,
        claimantId: uid,
      );
    } catch (_) {}

    try {
      final ownerName = _auth.currentUser?.displayName?.trim();
      final who =
          (ownerName == null || ownerName.isEmpty) ? 'The owner' : ownerName;
      await _notificationService.createNotification(
        recipientId: finderId,
        type: NotificationType.claimApproved,
        title: 'Item Returned',
        message: '$who confirmed you returned "${item.title}". Thank you!',
        relatedItemId: item.id,
        relatedClaimId: returnId,
      );
    } catch (_) {}

    return returnId;
  }

  /// Undoes a claim while the post is still in the archive: the post goes
  /// back to Lost/Found and the other person is told.
  Future<void> undoClaim(ItemModel item) async {
    final uid = _uid;
    if (item.ownerId != uid) {
      throw Exception('Only the person who posted this can undo the claim.');
    }
    if (!item.isClaimed) return;

    final restored = item.statusBeforeClaim;
    await _items.doc(item.id).update({
      'status': restored,
      'claimedFrom': FieldValue.delete(),
      'claimedBy': FieldValue.delete(),
      'claimedByName': FieldValue.delete(),
      'claimedAt': FieldValue.delete(),
    });

    final otherId = item.claimedBy ?? '';
    if (otherId.isEmpty) return;

    // A Found post's approved claim becomes Rejected, so the claimant can
    // keep talking and resend it if things get sorted out.
    final claimId = '${item.id}_$otherId';
    if (restored == 'Found') {
      try {
        final claimRef = _claims.doc(claimId);
        final snap = await claimRef.get();
        final status = (snap.data()?['status'] as String? ?? '').toLowerCase();
        if (snap.exists && status == 'approved') {
          await claimRef.update({'status': 'Rejected'});
        }
      } catch (_) {}
    }

    try {
      await _notificationService.createNotification(
        recipientId: otherId,
        type: NotificationType.claimUpdate,
        title: 'Claim Undone',
        message: restored == 'Found'
            ? 'The finder undid the claim on "${item.title}". You can keep '
                'chatting and resend your claim.'
            : 'The owner marked "${item.title}" as not returned yet.',
        relatedItemId: item.id,
        relatedClaimId: restored == 'Found' ? claimId : null,
      );
    } catch (_) {}
  }

  /// Deletes an archived post for good once its archive time is up: the
  /// post, the chat with the other person (and its messages) and, for a
  /// Found post, the approved claim. Runs on the owner's device.
  Future<void> purgeArchivedItem(ItemModel item) async {
    final uid = _uid;
    if (item.ownerId != uid || !item.isClaimed) return;

    final otherId = item.claimedBy ?? '';
    await _deleteResolvedData(
      claimId: item.statusBeforeClaim == 'Found' && otherId.isNotEmpty
          ? '${item.id}_$otherId'
          : null,
      itemId: item.id,
      ownerId: uid,
      claimantId: otherId,
    );
  }

  /// Deletes the resolved item, claim, conversation and its messages.
  /// Firestore rules in this project explicitly allow this cleanup only for
  /// authenticated participants/owners. [claimantId] may be '' (no chat to
  /// remove) and [claimId] null (no claim, e.g. a Lost post).
  Future<void> _deleteResolvedData({
    required String? claimId,
    required String itemId,
    required String ownerId,
    required String claimantId,
  }) async {
    if (claimantId.isEmpty) {
      await _items.doc(itemId).delete();
      return;
    }

    final ids = [ownerId, claimantId]..sort();
    final deterministicId = '${itemId}_${ids.join('_')}';

    final conversationRefs = <DocumentReference<Map<String, dynamic>>>[];
    final deterministicRef = _firestore
        .collection('conversations')
        .doc(deterministicId);

    if ((await deterministicRef.get()).exists) {
      conversationRefs.add(deterministicRef);
    }

    // Find older conversations created before deterministic conversation IDs.
    try {
      final legacy = await _firestore
          .collection('conversations')
          .where('postId', isEqualTo: itemId)
          .where('participantIds', arrayContains: claimantId)
          .get();

      for (final doc in legacy.docs) {
        final participants = List<String>.from(
          doc.data()['participantIds'] as List<dynamic>? ?? const [],
        );
        if (participants.length == 2 &&
            participants.contains(ownerId) &&
            participants.contains(claimantId) &&
            !conversationRefs.any((ref) => ref.id == doc.id)) {
          conversationRefs.add(doc.reference);
        }
      }
    } catch (_) {
      // The deterministic conversation is still cleaned up below.
    }

    final messageRefs = <DocumentReference<Map<String, dynamic>>>[];
    for (final conversationRef in conversationRefs) {
      try {
        final messages = await conversationRef.collection('messages').get();
        messageRefs.addAll(messages.docs.map((doc) => doc.reference));
      } catch (_) {}
    }

    // Firestore batches have a 500-operation limit. Keep a little room for
    // safety and delete messages in chunks.
    for (var start = 0; start < messageRefs.length; start += 450) {
      final end = (start + 450 < messageRefs.length)
          ? start + 450
          : messageRefs.length;
      final batch = _firestore.batch();
      for (final ref in messageRefs.sublist(start, end)) {
        batch.delete(ref);
      }
      await batch.commit();
    }

    final cleanupBatch = _firestore.batch();
    for (final ref in conversationRefs) {
      cleanupBatch.delete(ref);
    }
    cleanupBatch.delete(_items.doc(itemId));
    if (claimId != null) {
      // Deleting a claim that isn't there would fail the whole batch.
      final claimSnap = await claimRefFor(claimId).get();
      if (claimSnap.exists) cleanupBatch.delete(claimRefFor(claimId));
    }
    await cleanupBatch.commit();
  }

  DocumentReference<Map<String, dynamic>> claimRefFor(String claimId) =>
      _claims.doc(claimId);
}
