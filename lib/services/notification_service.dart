import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/notification_model.dart';
import '../models/item_model.dart';
import 'item_matching_service.dart';

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

  /// Notifies users who previously reported a Lost item when a Found item
  /// with a SIMILAR NAME in the SAME CATEGORY is posted.
  ///
  /// Both conditions are required, using the same keyword matcher as the
  /// pre-submit check and the My Posts "Check Matches" screen, so a Lost
  /// "Mobile Phone" is notified about a Found "iPhone 13" but not about a
  /// Found "Laptop" or "Phone Charger" in the same category.
  ///
  /// This is intentionally done after the Found item is successfully written
  /// to Firestore. If the report was created offline, ItemRepository calls
  /// this method when the queued report finally syncs.
  Future<void> notifyLostUsersForFoundItem(ItemModel foundItem) async {
    if (foundItem.status.toLowerCase() != 'found') return;

    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Same category only (cheap server-side filter)...
    final snapshot = await _items
        .where('category', isEqualTo: foundItem.category)
        .get();

    final foundCreatedAt =
        foundItem.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

    // ...then keep only Lost reports that existed before this Found item.
    final lostCandidates = snapshot.docs
        .map(ItemModel.fromDoc)
        .where((lost) {
      if (lost.status.toLowerCase() != 'lost') return false;
      if (lost.ownerId.isEmpty) return false;

      final createdAt = lost.createdAt;
      if (createdAt != null && !createdAt.isBefore(foundCreatedAt)) {
        return false;
      }
      return true;
    })
        .toList();

    if (lostCandidates.isEmpty) return;

    // ...and finally require a similar name (shared keyword).
    final matches = ItemMatchingService.findMatchesForDraft(
      title: foundItem.title,
      category: foundItem.category,
      status: foundItem.status,
      candidates: lostCandidates,
      currentUserId: currentUser.uid,
      excludeItemId: foundItem.id,
      limit: 1000,
    );

    // Best match first, so each person gets at most one notification
    // (for their closest Lost report).
    final notifiedUsers = <String>{};

    for (final match in matches) {
      if (!match.sameCategory) continue;

      final lost = match.item;
      if (!notifiedUsers.add(lost.ownerId)) continue;

      try {
        await createNotification(
          recipientId: lost.ownerId,
          type: NotificationType.categoryMatch,
          title: 'Possible Match Found',
          message:
          'A found item named "${foundItem.title}" in the '
              '"${foundItem.category}" category looks similar to your lost '
              'item "${lost.title}". Tap to view it.',
          relatedItemId: foundItem.id,
        );
      } catch (_) {
        // One failed notification shouldn't stop the others.
      }
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