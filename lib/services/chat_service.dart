import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/conversation_model.dart';
import '../models/message_model.dart';

/// Firestore-backed one-to-one messaging.
///
/// conversations/{conversationId}
///   postId, itemName, itemImageUrl, itemType
///   participantIds: [uidA, uidB]
///   participantNames: { uidA: '...', uidB: '...' }
///   lastMessage, lastMessageTime
///   unreadCounts: { uidA: 0, uidB: 0 }
///
/// conversations/{conversationId}/messages/{messageId}
///   senderId, senderName, text, timestamp, isRead
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _conversations =>
      _firestore.collection('conversations');

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('You must be signed in to use messaging.');
    }
    return user.uid;
  }

  String _displayName(User user) {
    final name = user.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final email = user.email?.trim();
    if (email != null && email.isNotEmpty) return email;
    return 'Unknown User';
  }

  /// Live conversations for the signed-in user.
  Stream<List<ConversationModel>> streamConversations() {
    final currentUserId = _uid;

    return _conversations
        .where('participantIds', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
          .map((doc) => ConversationModel.fromDoc(doc, currentUserId))
          .toList(),
    );
  }

  /// One-off fetch for pull-to-refresh, mirroring [streamConversations].
  Future<List<ConversationModel>> fetchConversationsOnce() async {
    final currentUserId = _uid;
    final snap = await _conversations
        .where('participantIds', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .get();
    return snap.docs
        .map((doc) => ConversationModel.fromDoc(doc, currentUserId))
        .toList();
  }

  /// Live messages, oldest first.
  Stream<List<MessageModel>> streamMessages(String conversationId) {
    return _conversations
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .map(
          (snap) => snap.docs
          .map((doc) => MessageModel.fromDoc(doc, conversationId))
          .toList(),
    );
  }

  /// Creates/reuses a conversation for a post and two users.
  ///
  /// The deterministic id prevents two rapid taps from creating duplicate
  /// conversations. Older conversations created by the previous version are
  /// still discovered by the legacy query below.
  Future<String> getOrCreateConversation({
    required String postId,
    required String itemName,
    required String itemImageUrl,
    required String itemType,
    required String otherUserId,
    required String otherUserName,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('You must be signed in to use messaging.');
    }

    final currentUserId = currentUser.uid;
    if (postId.trim().isEmpty) throw Exception('Invalid post.');
    if (otherUserId.trim().isEmpty || otherUserId == currentUserId) {
      throw Exception('You cannot message yourself.');
    }

    // Keep the id stable regardless of which participant starts the chat.
    final ids = [currentUserId, otherUserId]..sort();
    final deterministicId = '${postId.trim()}_${ids.join('_')}';
    final conversationRef = _conversations.doc(deterministicId);

    // First check the deterministic conversation. Firestore rules allow this
    // read when the document does not exist, while an existing document is
    // readable only by one of its participants. This avoids the
    // PERMISSION_DENIED error that occurs when starting a brand-new chat.
    final existing = await conversationRef.get();
    if (existing.exists) {
      final existingData = existing.data();
      final existingParticipants = List<String>.from(
        existingData?['participantIds'] as List<dynamic>? ?? const [],
      );

      if (existingParticipants.length == 2 &&
          existingParticipants.contains(currentUserId) &&
          existingParticipants.contains(otherUserId)) {
        return existing.id;
      }

      throw Exception('A conversation with this ID already exists.');
    }

    // Discover conversations made by the older implementation.
    final legacy = await _conversations
        .where('postId', isEqualTo: postId)
        .where('participantIds', arrayContains: currentUserId)
        .get();

    for (final doc in legacy.docs) {
      final ids = List<String>.from(
        doc.data()['participantIds'] as List<dynamic>? ?? const [],
      );
      if (ids.length == 2 && ids.contains(otherUserId)) return doc.id;
    }

    final currentUserName = _displayName(currentUser);

    await conversationRef.set({
      'postId': postId.trim(),
      'itemName': itemName.trim(),
      'itemImageUrl': itemImageUrl,
      'itemType': itemType.trim(),
      'participantIds': ids,
      'participantNames': {
        currentUserId: currentUserName,
        otherUserId: otherUserName.trim().isEmpty ? 'User' : otherUserName.trim(),
      },
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCounts': {
        currentUserId: 0,
        otherUserId: 0,
      },
    });

    return conversationRef.id;
  }

  /// Sends a text message and atomically updates the conversation preview and
  /// recipient unread count.
  Future<void> sendMessage({
    required String conversationId,
    required String text,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('You must be signed in to send messages.');
    }

    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    if (trimmed.length > 2000) {
      throw Exception('Message is too long. Maximum is 2000 characters.');
    }

    final conversationRef = _conversations.doc(conversationId);

    await _firestore.runTransaction((transaction) async {
      final conversationSnap = await transaction.get(conversationRef);
      if (!conversationSnap.exists) {
        throw Exception('Conversation no longer exists.');
      }

      final data = conversationSnap.data()!;
      final participantIds = List<String>.from(
        data['participantIds'] as List<dynamic>? ?? const [],
      );

      if (!participantIds.contains(currentUser.uid) ||
          participantIds.length != 2) {
        throw Exception('You are not a participant in this conversation.');
      }

      final otherUserId = participantIds.firstWhere(
            (id) => id != currentUser.uid,
        orElse: () => '',
      );

      final unreadCounts = Map<String, dynamic>.from(
        data['unreadCounts'] as Map<String, dynamic>? ?? const {},
      );
      if (otherUserId.isNotEmpty) {
        unreadCounts[otherUserId] =
            ((unreadCounts[otherUserId] as num?)?.toInt() ?? 0) + 1;
      }

      final messageRef = conversationRef.collection('messages').doc();
      transaction.set(messageRef, {
        'senderId': currentUser.uid,
        'senderName': _displayName(currentUser),
        'text': trimmed,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      transaction.update(conversationRef, {
        'lastMessage': trimmed,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCounts': unreadCounts,
      });
    });
  }

  /// Clears the signed-in user's conversation-level unread count.
  Future<void> markConversationRead(String conversationId) async {
    final currentUserId = _uid;
    await _conversations.doc(conversationId).update({
      'unreadCounts.$currentUserId': 0,
    });
  }

  // ============================================================
  // OFFLINE SYNC HELPER
  // ============================================================

  /// Sends a message using a caller-supplied [messageId] instead of letting
  /// Firestore generate one. Used to push a message that was written to the
  /// local database while offline: reusing the same id it was given locally
  /// means a retried/duplicated sync attempt can never create two copies of
  /// the same message.
  Future<void> sendMessageWithId({
    required String messageId,
    required String conversationId,
    required String senderId,
    required String senderName,
    required String text,
    required DateTime timestamp,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final conversationRef = _conversations.doc(conversationId);
    final messageRef = conversationRef.collection('messages').doc(messageId);

    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(messageRef);
      if (existing.exists) return; // Already synced - avoid a duplicate.

      final conversationSnap = await transaction.get(conversationRef);
      if (!conversationSnap.exists) {
        throw Exception('Conversation no longer exists.');
      }

      final data = conversationSnap.data()!;
      final participantIds = List<String>.from(
        data['participantIds'] as List<dynamic>? ?? const [],
      );

      final otherUserId = participantIds.firstWhere(
            (id) => id != senderId,
        orElse: () => '',
      );

      final unreadCounts = Map<String, dynamic>.from(
        data['unreadCounts'] as Map<String, dynamic>? ?? const {},
      );
      if (otherUserId.isNotEmpty) {
        unreadCounts[otherUserId] =
            ((unreadCounts[otherUserId] as num?)?.toInt() ?? 0) + 1;
      }

      transaction.set(messageRef, {
        'senderId': senderId,
        'senderName': senderName,
        'text': trimmed,
        'timestamp': Timestamp.fromDate(timestamp),
        'isRead': false,
      });

      transaction.update(conversationRef, {
        'lastMessage': trimmed,
        'lastMessageTime': Timestamp.fromDate(timestamp),
        'unreadCounts': unreadCounts,
      });
    });
  }
}