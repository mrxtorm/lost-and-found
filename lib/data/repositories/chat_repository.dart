import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../../models/conversation_model.dart';
import '../../models/message_model.dart';
import '../../services/chat_service.dart';
import '../local/app_database.dart';

/// Offline-first access point for conversations and messages.
///
/// Conversations are only ever created online (starting a brand-new chat
/// needs the server to dedupe against an existing one), but once a
/// conversation is cached locally, its messages can be read - and new ones
/// sent - entirely offline; sends are queued locally and pushed once a
/// connection is available.
class ChatRepository {
  final AppDatabase _db;
  final ChatService _chatService;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<List<ConversationModel>>? _conversationsSub;
  final Map<String, StreamSubscription<List<MessageModel>>> _messageSubs = {};
  String? _viewerId;

  ChatRepository({
    required AppDatabase database,
    ChatService? chatService,
  })  : _db = database,
        _chatService = chatService ?? ChatService();

  /// Starts a live Firestore listener for [viewerId]'s conversation list.
  void startRemoteSync(String viewerId) {
    if (_viewerId == viewerId && _conversationsSub != null) return;
    _viewerId = viewerId;
    _conversationsSub?.cancel();
    _conversationsSub = _chatService.streamConversations().listen(
          (serverConversations) {
        _db.syncConversationsFromServer(
          viewerId,
          serverConversations
              .map((c) => _toCompanion(c, viewerId))
              .toList(),
        );
      },
      onError: (_) {},
    );
  }

  void stopRemoteSync() {
    _conversationsSub?.cancel();
    _conversationsSub = null;
    _viewerId = null;
    for (final sub in _messageSubs.values) {
      sub.cancel();
    }
    _messageSubs.clear();
  }

  void dispose() => stopRemoteSync();

  // ---------------------------------------------------------------------
  // READS
  // ---------------------------------------------------------------------

  Stream<List<ConversationModel>> watchConversations(String viewerId) {
    return _db.watchConversations(viewerId).map(
          (rows) => rows.map((r) => _toModel(r, viewerId)).toList(),
    );
  }

  /// One-off refresh for pull-to-refresh, same idea as
  /// [ItemRepository.refreshItems]: fetch now, merge through the same
  /// [AppDatabase.syncConversationsFromServer] path the live listener uses.
  Future<void> refreshConversations(String viewerId) async {
    final serverConversations = await _chatService.fetchConversationsOnce();
    await _db.syncConversationsFromServer(
      viewerId,
      serverConversations.map((c) => _toCompanion(c, viewerId)).toList(),
    );
  }

  /// Cached messages for [conversationId], oldest first. Also makes sure a
  /// live Firestore listener is running for this conversation so newly
  /// arriving messages keep flowing into the cache while it's open.
  Stream<List<MessageModel>> watchMessages(String conversationId) {
    _ensureMessageListener(conversationId);
    return _db.watchMessages(conversationId).map(
          (rows) => rows.map((r) => _toMessageModel(r)).toList(),
    );
  }

  void _ensureMessageListener(String conversationId) {
    if (_messageSubs.containsKey(conversationId)) return;
    _messageSubs[conversationId] =
        _chatService.streamMessages(conversationId).listen(
              (serverMessages) {
            _db.syncMessagesFromServer(
              conversationId,
              serverMessages.map(_toMessageCompanion).toList(),
            );
          },
          onError: (_) {},
        );
  }

  // ---------------------------------------------------------------------
  // WRITES
  // ---------------------------------------------------------------------

  /// Starting a brand-new conversation needs the server (to safely dedupe
  /// concurrent chat requests for the same item/pair of users), so this
  /// still requires a connection - same as before this feature was added.
  Future<String> getOrCreateConversation({
    required String postId,
    required String itemName,
    required String itemImageUrl,
    required String itemType,
    required String otherUserId,
    required String otherUserName,
  }) {
    return _chatService.getOrCreateConversation(
      postId: postId,
      itemName: itemName,
      itemImageUrl: itemImageUrl,
      itemType: itemType,
      otherUserId: otherUserId,
      otherUserName: otherUserName,
    );
  }

  Future<void> sendMessage({
    required String conversationId,
    required String text,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('You must be signed in to send messages.');
    }

    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    if (trimmed.length > 2000) {
      throw Exception('Message is too long. Maximum is 2000 characters.');
    }

    final conversation = await _db.getConversation(conversationId);
    if (conversation == null) {
      throw Exception('Conversation no longer exists.');
    }

    final senderName =
    (user.displayName != null && user.displayName!.trim().isNotEmpty)
        ? user.displayName!
        : (user.email ?? 'Unknown User');
    final id = const Uuid().v4();
    final now = DateTime.now();

    await _db.upsertLocalMessage(MessagesCompanion.insert(
      id: id,
      conversationId: Value(conversationId),
      senderId: Value(user.uid),
      senderName: Value(senderName),
      content: Value(trimmed),
      timestamp: Value(now),
      isRead: const Value(false),
      synced: const Value(false),
      pendingCreate: const Value(true),
    ));

    // Reflect the preview optimistically too.
    await _db.upsertLocalConversation(ConversationsCompanion(
      id: Value(conversationId),
      lastMessage: Value(trimmed),
      lastMessageTime: Value(now),
    ));

    unawaited(_pushMessage(id));
  }

  Future<void> markConversationRead(String conversationId) async {
    await _db.setConversationReadLocally(conversationId, pending: true);
    try {
      await _chatService.markConversationRead(conversationId);
      await _db.setConversationReadLocally(conversationId, pending: false);
    } catch (_) {
      // Left pending=true - retried on the next sync pass.
    }
  }

  // ---------------------------------------------------------------------
  // SYNC
  // ---------------------------------------------------------------------

  Future<void> pushPending(String currentUserId) async {
    final pendingMessages = await _db.allPendingMessageOps();
    for (final row in pendingMessages) {
      if (row.senderId != currentUserId) continue;
      await _pushMessage(row.id);
    }

    if (_viewerId == currentUserId) {
      final pendingReads = await _db.pendingMarkReadConversations(currentUserId);
      for (final conversation in pendingReads) {
        try {
          await _chatService.markConversationRead(conversation.id);
          await _db.setConversationReadLocally(conversation.id, pending: false);
        } catch (_) {
          // Retried on the next sync pass.
        }
      }
    }
  }

  Future<bool> hasPendingWork(String currentUserId) async {
    final pendingMessages = await _db.allPendingMessageOps();
    if (pendingMessages.any((m) => m.senderId == currentUserId)) return true;
    if (_viewerId != currentUserId) return false;
    final pendingReads = await _db.pendingMarkReadConversations(currentUserId);
    return pendingReads.isNotEmpty;
  }

  Future<void> _pushMessage(String id) async {
    try {
      final row = await _db.getMessage(id);
      if (row == null || !row.pendingCreate) return;

      await _chatService.sendMessageWithId(
        messageId: row.id,
        conversationId: row.conversationId,
        senderId: row.senderId,
        senderName: row.senderName,
        text: row.content,
        timestamp: row.timestamp,
      );

      await _db.markMessageSynced(id);
    } catch (_) {
      // Leave pendingCreate=true - retried on the next sync pass.
    }
  }

  // ---------------------------------------------------------------------
  // MAPPING
  // ---------------------------------------------------------------------

  ConversationsCompanion _toCompanion(
      ConversationModel conversation,
      String viewerId,
      ) {
    return ConversationsCompanion.insert(
      id: conversation.id,
      viewerId: Value(viewerId),
      postId: Value(conversation.postId),
      itemName: Value(conversation.itemName),
      itemImageUrl: Value(conversation.itemImageUrl),
      itemType: Value(conversation.itemType),
      participantIdsJson: Value(jsonEncode(conversation.participantIds)),
      otherUserId: Value(conversation.otherUserId),
      otherUserName: Value(conversation.otherUserName),
      lastMessage: Value(conversation.lastMessage),
      lastMessageTime: Value(conversation.lastMessageTime),
      unreadCount: Value(conversation.unreadCount),
    );
  }

  ConversationModel _toModel(ConversationRow row, String viewerId) {
    final participantIds = (jsonDecode(row.participantIdsJson) as List)
        .map((e) => e.toString())
        .toList();
    return ConversationModel(
      id: row.id,
      postId: row.postId,
      itemName: row.itemName,
      itemImageUrl: row.itemImageUrl,
      itemType: row.itemType,
      participantIds: participantIds,
      otherUserId: row.otherUserId,
      otherUserName: row.otherUserName,
      lastMessage: row.lastMessage,
      lastMessageTime: row.lastMessageTime,
      unreadCount: row.unreadCount,
    );
  }

  MessagesCompanion _toMessageCompanion(MessageModel message) {
    return MessagesCompanion.insert(
      id: message.id,
      conversationId: Value(message.conversationId),
      senderId: Value(message.senderId),
      senderName: Value(message.senderName),
      content: Value(message.text),
      timestamp: Value(message.timestamp),
      isRead: Value(message.isRead),
    );
  }

  MessageModel _toMessageModel(MessageRow row) {
    return MessageModel(
      id: row.id,
      conversationId: row.conversationId,
      senderId: row.senderId,
      senderName: row.senderName,
      text: row.content,
      timestamp: row.timestamp,
      isRead: row.isRead,
    );
  }
}