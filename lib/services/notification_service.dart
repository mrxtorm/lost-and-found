import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/notification_model.dart';

/// Handles reading and writing in-app notifications.
///
/// There's no server here, so notifications are created client-side at the
/// moment an event happens (a claim is submitted, a claim is resolved, a
/// matching item appears). That's fine for this app's scale, but note it
/// means a notification is only created if the triggering action goes
/// through [ItemService]/[ClaimService] rather than being written directly.
class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection('notifications');

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('You must be signed in.');
    }
    return user.uid;
  }

  /// Live stream of the current user's notifications, newest first.
  Stream<List<NotificationModel>> streamNotifications() {
    return _notifications
        .where('recipientId', isEqualTo: _uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(NotificationModel.fromDoc).toList());
  }

  /// One-off fetch for pull-to-refresh, mirroring [streamNotifications].
  Future<List<NotificationModel>> fetchNotificationsOnce() async {
    final snap = await _notifications
        .where('recipientId', isEqualTo: _uid)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map(NotificationModel.fromDoc).toList();
  }

  Future<void> createNotification({
    required String recipientId,
    required String type,
    required String title,
    required String message,
    String? relatedItemId,
    String? relatedClaimId,
  }) async {
    // Don't bother notifying someone about their own action.
    if (recipientId.isEmpty) return;

    final notification = NotificationModel(
      id: '',
      recipientId: recipientId,
      type: type,
      title: title,
      message: message,
      relatedItemId: relatedItemId,
      relatedClaimId: relatedClaimId,
      isRead: false,
    );

    await _notifications.add(notification.toMap());
  }

  Future<void> markAsRead(String notificationId) {
    return _notifications.doc(notificationId).update({'isRead': true});
  }

  Future<void> markAllAsRead() async {
    final snapshot = await _notifications
        .where('recipientId', isEqualTo: _uid)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}