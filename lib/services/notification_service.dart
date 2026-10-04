import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/notification_model.dart';
import '../models/item_model.dart';

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


  CollectionReference<Map<String, dynamic>> get _items =>
      _firestore.collection('items');

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

  /// Notifies users who previously reported a Lost item in the same
  /// category when a new Found item is posted.
  ///
  /// This is intentionally done after the Found item is successfully written
  /// to Firestore. If the report was created offline, ItemRepository calls
  /// this method when the queued report finally syncs.
  Future<void> notifyLostUsersForFoundItem(ItemModel foundItem) async {
    if (foundItem.status.toLowerCase() != 'found') return;

    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final snapshot = await _items
        .where('category', isEqualTo: foundItem.category)
        .get();

    final notifiedUsers = <String>{};
    final foundCreatedAt =
        foundItem.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final ownerId = data['ownerId'] as String? ?? '';
      final status = (data['status'] as String? ?? '').toLowerCase();

      if (ownerId.isEmpty ||
          ownerId == currentUser.uid ||
          status != 'lost' ||
          notifiedUsers.contains(ownerId)) {
        continue;
      }

      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
      if (createdAt != null && !createdAt.isBefore(foundCreatedAt)) {
        // Only notify users whose Lost report existed before this Found item.
        continue;
      }

      notifiedUsers.add(ownerId);

      await createNotification(
        recipientId: ownerId,
        type: NotificationType.categoryMatch,
        title: 'Possible Match Found',
        message:
            'A found item named "${foundItem.title}" was reported under '
            'the "${foundItem.category}" category. Tap to view it.',
        relatedItemId: foundItem.id,
      );
    }
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