import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/item_model.dart';
import '../models/message_model.dart';
import '../models/report_model.dart';

/// Lets users report fake/suspicious posts and abusive messages.
///
/// reports/{targetType}_{targetId}_{uid}: the deterministic id plus
/// create-only Firestore rules mean a user can report the same post or
/// message only once. Rules also check that contentPreview matches the
/// real post title / message text, so the snapshot admins see is genuine.
class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const maxDetailsLength = 300;

  CollectionReference<Map<String, dynamic>> get _reports =>
      _firestore.collection('reports');

  String? get _uid => _auth.currentUser?.uid;

  static String itemReportId(String itemId, String uid) =>
      '${ReportTarget.item}_${itemId}_$uid';

  static String messageReportId(String messageId, String uid) =>
      '${ReportTarget.message}_${messageId}_$uid';

  /// True if the current user already reported this content.
  Future<bool> hasReported(String reportId) async {
    try {
      final doc = await _reports.doc(reportId).get();
      return doc.exists;
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasReportedItem(String itemId) {
    final uid = _uid;
    if (uid == null) return Future.value(false);
    return hasReported(itemReportId(itemId, uid));
  }

  Future<bool> hasReportedMessage(String messageId) {
    final uid = _uid;
    if (uid == null) return Future.value(false);
    return hasReported(messageReportId(messageId, uid));
  }

  Future<void> reportItem({
    required ItemModel item,
    required String reason,
    required String details,
  }) {
    final uid = _requireUid();
    if (item.ownerId == uid) {
      throw Exception('You cannot report your own post.');
    }
    return _create(itemReportId(item.id, uid), {
      'targetType': ReportTarget.item,
      'targetId': item.id,
      'conversationId': '',
      'reporterId': uid,
      'reportedUserId': item.ownerId,
      'reportedUserName': item.username,
      'contentPreview': item.title,
      'reason': reason,
      'details': details.trim(),
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> reportMessage({
    required MessageModel message,
    required String reason,
    required String details,
  }) {
    final uid = _requireUid();
    if (message.senderId == uid) {
      throw Exception('You cannot report your own message.');
    }
    return _create(messageReportId(message.id, uid), {
      'targetType': ReportTarget.message,
      'targetId': message.id,
      'conversationId': message.conversationId,
      'reporterId': uid,
      'reportedUserId': message.senderId,
      'reportedUserName': message.senderName,
      'contentPreview': message.text,
      'reason': reason,
      'details': details.trim(),
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  String _requireUid() {
    final uid = _uid;
    if (uid == null) throw Exception('You must be signed in.');
    return uid;
  }

  Future<void> _create(String reportId, Map<String, dynamic> data) async {
    final details = data['details'] as String;
    if (details.length > maxDetailsLength) {
      throw Exception('Details must be $maxDetailsLength characters or less.');
    }

    final ref = _reports.doc(reportId);
    if ((await ref.get()).exists) {
      throw Exception('You already reported this. An admin will review it.');
    }

    try {
      await ref.set(data);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'This content can no longer be reported. It may have been '
          'changed or removed.',
        );
      }
      rethrow;
    }
  }
}
