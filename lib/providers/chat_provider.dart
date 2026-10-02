import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/repositories/chat_repository.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

/// Owns the live conversation list. Per-conversation messages are still
/// streamed on demand via [streamMessages] since only one conversation
/// screen is ever open at a time.
///
/// Data comes from [ChatRepository], which is offline-first: conversations
/// and messages are read from the local cache immediately, and a sent
/// message is saved locally first (so it's never lost) and pushed to
/// Firestore in the background.
///
/// [ChatRepository] requires a signed-in user, so this only subscribes once
/// [setCurrentUserId] has been called with a real uid (done from
/// [AuthGate] whenever auth state changes).
class ChatProvider with ChangeNotifier {
  final ChatRepository _chatRepository;

  StreamSubscription<List<ConversationModel>>? _conversationsSub;
  List<ConversationModel> _conversations = [];
  bool _isLoading = false;
  Object? _error;
  String? _currentUserId;

  ChatProvider(this._chatRepository);

  void setCurrentUserId(String? uid) {
    if (uid == _currentUserId) return;
    _currentUserId = uid;
    _conversationsSub?.cancel();
    _conversations = [];
    _error = null;

    if (uid == null) {
      _chatRepository.stopRemoteSync();
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    _chatRepository.startRemoteSync(uid);
    _conversationsSub = _chatRepository.watchConversations(uid).listen(
          (conversations) {
        _conversations = conversations;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object error) {
        _error = error;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  List<ConversationModel> get conversations => _conversations;
  bool get isLoading => _isLoading;
  Object? get error => _error;

  /// Pull-to-refresh entry point for the Messages screen. Same pattern as
  /// [ItemProvider.refreshHome]: the result flows back through the local
  /// database and the existing stream subscription picks it up on its own.
  Future<void> refreshConversations() async {
    final uid = _currentUserId;
    if (uid == null) return;
    try {
      await _chatRepository.refreshConversations(uid);
    } catch (_) {
      // No connection or a transient error - keep showing what's cached.
    }
  }

  ConversationModel? conversationById(String id) {
    for (final conversation in _conversations) {
      if (conversation.id == id) return conversation;
    }
    return null;
  }

  Stream<List<MessageModel>> streamMessages(String conversationId) {
    return _chatRepository.watchMessages(conversationId);
  }

  Future<String> getOrCreateConversation({
    required String postId,
    required String itemName,
    required String itemImageUrl,
    required String itemType,
    required String otherUserId,
    required String otherUserName,
  }) {
    return _chatRepository.getOrCreateConversation(
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
  }) {
    return _chatRepository.sendMessage(
      conversationId: conversationId,
      text: text,
    );
  }

  Future<void> markConversationRead(String conversationId) {
    return _chatRepository.markConversationRead(conversationId);
  }

  @override
  void dispose() {
    _conversationsSub?.cancel();
    super.dispose();
  }
}