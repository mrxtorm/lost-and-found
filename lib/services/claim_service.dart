import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/claim_model.dart';
import '../models/item_model.dart';
import '../models/notification_model.dart';
import 'notification_service.dart';
import 'chat_service.dart';

/// Handles claim requests separately from the item's Lost/Found type.
///
/// IMPORTANT:
/// - items/{itemId}.status stays Lost/Found while a claim is pending.
/// - claims/{itemId}.status contains Pending/Approved/Rejected.
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
    return _claims.doc(itemId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ClaimModel.fromDoc(doc);
    });
  }

  /// One-time check used by the Claim Item button. This also works after an
  /// app restart because the claimant is allowed to read their own claim.
  Future<bool> hasPendingClaimForCurrentUser(String itemId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final doc = await _claims.doc(itemId).get();
      if (!doc.exists) return false;
      final data = doc.data();
      return data?['claimantId'] == user.uid &&
          (data?['status'] as String? ?? '').toLowerCase() == 'pending';
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

    final claimRef = _claims.doc(item.id);
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
        messageId: 'claim_${item.id}',
        conversationId: conversationId,
        senderId: user.uid,
        senderName: claimantName,
        text: 'Claim request submitted for "${item.title}".',
        timestamp: DateTime.now(),
      );
    } catch (_) {
      // The claim remains valid even if conversation creation temporarily
      // fails. The next online sync/retry can still be used to recover it.
    }

    await _notificationService.createNotification(
      recipientId: item.ownerId,
      type: NotificationType.claimReceived,
      title: 'Claim Request Received',
      message: '$claimantName submitted a claim for "${item.title}".',
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

    // Notify first while the claim still exists, then remove the resolved
    // data. The notification itself contains no sensitive claim answers.
    try {
      await _notificationService.createNotification(
        recipientId: claimantId,
        type: NotificationType.claimApproved,
        title: 'Claim Approved',
        message: 'Your claim for "$itemTitle" was approved.',
        relatedItemId: itemId,
        relatedClaimId: claimId,
      );
    } catch (_) {
      // Cleanup should still happen even if notification creation fails.
    }

    // Mark it Approved first because the Firestore delete rule only permits
    // the finder to delete an approved claim.
    await claimRef.update({'status': 'Approved'});

    await _deleteResolvedData(
      claimId: claimId,
      itemId: itemId,
      ownerId: ownerId,
      claimantId: claimantId,
    );
  }

  /// Deletes the resolved item, claim, conversation and its messages.
  /// Firestore rules in this project explicitly allow this cleanup only for
  /// authenticated participants/owners.
  Future<void> _deleteResolvedData({
    required String claimId,
    required String itemId,
    required String ownerId,
    required String claimantId,
  }) async {
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
    cleanupBatch.delete(claimRefFor(claimId));
    await cleanupBatch.commit();
  }

  DocumentReference<Map<String, dynamic>> claimRefFor(String claimId) =>
      _claims.doc(claimId);
}
