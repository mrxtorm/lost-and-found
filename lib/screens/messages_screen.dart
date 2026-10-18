import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';

import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/app_feedback.dart';
import '../widgets/item_ui.dart';

import '../models/conversation_model.dart';
import '../providers/chat_provider.dart';
import 'conversation_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ConversationModel> _filter(List<ConversationModel> conversations) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return conversations;

    return conversations.where((conversation) {
      return conversation.itemName.toLowerCase().contains(query) ||
          conversation.otherUserName.toLowerCase().contains(query) ||
          conversation.lastMessage.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search conversations',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                ),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: Builder(builder: (context) {
              if (chatProvider.error != null) {
                return _StateMessage(
                  icon: Icons.error_outline,
                  text: "We couldn't load your messages.",
                  onRetry: chatProvider.refreshConversations,
                );
              }

              if (chatProvider.isLoading) {
                return const LoadingView(label: 'Loading conversations');
              }

              final conversations = _filter(chatProvider.conversations);
              if (conversations.isEmpty) {
                return RefreshIndicator(
                  onRefresh: chatProvider.refreshConversations,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      _StateMessage(
                        icon: Icons.chat_bubble_outline,
                        text: _searchQuery.isEmpty
                            ? 'No conversations yet.'
                            : 'No conversations match your search.',
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: chatProvider.refreshConversations,
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: conversations.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    indent: 88,
                  ),
                  itemBuilder: (context, index) {
                    final conversation = conversations[index];
                    return _ConversationTile(
                      conversation: conversation,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ConversationScreen(
                              conversationId: conversation.id,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationModel conversation;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.onTap,
  });

  String _formatTime(DateTime dateTime) {
    if (dateTime.millisecondsSinceEpoch == 0) return '';
    final now = DateTime.now();
    if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day) {
      final hour = dateTime.hour == 0
          ? 12
          : dateTime.hour > 12
          ? dateTime.hour - 12
          : dateTime.hour;
      return '$hour:${dateTime.minute.toString().padLeft(2, '0')} '
          '${dateTime.hour >= 12 ? 'PM' : 'AM'}';
    }
    return '${dateTime.month}/${dateTime.day}';
  }

  @override
  Widget build(BuildContext context) {
    final unread = conversation.unreadCount > 0;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: _ItemImage(url: conversation.itemImageUrl),
      title: Row(
        children: [
          Expanded(
            child: Text(
              conversation.otherUserName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatTime(conversation.lastMessageTime),
            style: TextStyle(
              fontSize: 11,
              fontWeight: unread ? FontWeight.w700 : FontWeight.normal,
              color: unread
                  ? Theme.of(context).colorScheme.primary
                  : AppColors.muted,
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.itemName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    conversation.lastMessage.isEmpty
                        ? 'Start a conversation'
                        : conversation.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: unread ? Colors.black87 : AppColors.muted,
                      fontWeight: unread ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            if (unread)
              Container(
                margin: const EdgeInsets.only(left: 8),
                constraints: const BoxConstraints(minWidth: 22),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  conversation.unreadCount > 99
                      ? '99+'
                      : '${conversation.unreadCount}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
      onTap: onTap,
    );
  }
}

class _ItemImage extends StatelessWidget {
  final String url;
  const _ItemImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.line,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: url.isEmpty
          ? const Icon(Icons.image_outlined, color: AppColors.muted)
          : Image(
        image: CachedNetworkImageProvider(
          optimizedImageUrl(url, width: 300),
          maxWidth: 300,
        ),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.image_outlined,
          color: AppColors.muted,
        ),
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onRetry;

  const _StateMessage({
    required this.icon,
    required this.text,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (onRetry != null) return ErrorState(message: text, onRetry: onRetry);
    return EmptyState(
      icon: icon,
      title: text,
      message: 'Start a chat from an item you found or lost.',
    );
  }
}
