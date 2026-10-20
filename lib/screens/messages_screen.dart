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
  static const _all = 'All';
  static const _unread = 'Unread';

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _tab = _all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ConversationModel> _filter(List<ConversationModel> conversations) {
    final query = _searchQuery.trim().toLowerCase();

    return conversations.where((conversation) {
      if (_tab == _unread && conversation.unreadCount == 0) return false;
      if (query.isEmpty) return true;
      return conversation.itemName.toLowerCase().contains(query) ||
          conversation.otherUserName.toLowerCase().contains(query) ||
          conversation.lastMessage.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final unreadChats =
        chatProvider.conversations.where((c) => c.unreadCount > 0).length;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        toolbarHeight: 64,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Messages',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
                color: AppColors.ink,
              ),
            ),
            if (unreadChats > 0)
              Text(
                unreadChats == 1
                    ? '1 unread conversation'
                    : '$unreadChats unread conversations',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              style: const TextStyle(fontSize: 16),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search people, items or messages',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                fillColor: AppColors.bg,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SegmentedTabs(
              options: const [_all, _unread],
              selected: _tab,
              onChanged: (option) => setState(() => _tab = option),
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
                      if (_searchQuery.isNotEmpty)
                        const _StateMessage(
                          icon: Icons.search_off_rounded,
                          text: 'No matches',
                          message: 'Try a different name or item.',
                        )
                      else if (_tab == _unread)
                        const _StateMessage(
                          icon: Icons.mark_chat_read_outlined,
                          text: "You're all caught up",
                          message: 'No unread messages right now.',
                        )
                      else
                        const _StateMessage(
                          icon: Icons.chat_bubble_outline_rounded,
                          text: 'No conversations yet',
                          message:
                              'Start a chat from an item you found or lost.',
                        ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: chatProvider.refreshConversations,
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(top: 4, bottom: 16),
                  itemCount: conversations.length,
                  separatorBuilder: (_, _) => const Divider(
                    height: 1,
                    indent: 100,
                    endIndent: 16,
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

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  String _formatTime(DateTime dateTime) {
    if (dateTime.millisecondsSinceEpoch == 0) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final daysAgo = today.difference(day).inDays;

    if (daysAgo == 0) {
      final hour = dateTime.hour == 0
          ? 12
          : dateTime.hour > 12
              ? dateTime.hour - 12
              : dateTime.hour;
      return '$hour:${dateTime.minute.toString().padLeft(2, '0')} '
          '${dateTime.hour >= 12 ? 'PM' : 'AM'}';
    }
    if (daysAgo == 1) return 'Yesterday';
    if (daysAgo < 7) return _weekdays[dateTime.weekday - 1];
    return '${dateTime.month}/${dateTime.day}/${dateTime.year % 100}';
  }

  @override
  Widget build(BuildContext context) {
    final unread = conversation.unreadCount > 0;
    final type = conversation.itemType.isEmpty
        ? ''
        : conversation.itemType[0].toUpperCase() +
            conversation.itemType.substring(1).toLowerCase();

    return Material(
      color: unread
          ? AppColors.primarySoft.withValues(alpha: 0.55)
          : AppColors.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item photo with the other person's avatar tucked in the
              // corner, so you can tell both "what" and "who" at a glance.
              SizedBox(
                width: 70,
                height: 70,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _ItemImage(url: conversation.itemImageUrl),
                    Positioned(
                      right: -4,
                      bottom: -4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                        ),
                        child: UserAvatar(
                          name: conversation.otherUserName,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.otherUserName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  unread ? FontWeight.w800 : FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(conversation.lastMessageTime),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                unread ? FontWeight.w800 : FontWeight.w500,
                            color: unread
                                ? AppColors.primary
                                : AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (type.isNotEmpty) ...[
                          Icon(
                            statusIcon(type),
                            size: 15,
                            color: statusColor(type),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            conversation.itemName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: type.isEmpty
                                  ? AppColors.muted
                                  : statusColor(type),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.lastMessage.isEmpty
                                ? 'Start a conversation'
                                : conversation.lastMessage,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.35,
                              fontStyle: conversation.lastMessage.isEmpty
                                  ? FontStyle.italic
                                  : null,
                              color: unread ? AppColors.ink : AppColors.muted,
                              fontWeight:
                                  unread ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (unread)
                          Container(
                            margin: const EdgeInsets.only(left: 10),
                            constraints: const BoxConstraints(minWidth: 24),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              conversation.unreadCount > 99
                                  ? '99+'
                                  : '${conversation.unreadCount}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemImage extends StatelessWidget {
  final String url;
  const _ItemImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: AppColors.track,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      clipBehavior: Clip.antiAlias,
      child: url.isEmpty
          ? Icon(Icons.image_outlined, color: AppColors.muted, size: 28)
          : Image(
              image: CachedNetworkImageProvider(
                optimizedImageUrl(url, width: 300),
                maxWidth: 300,
              ),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Icon(
                Icons.image_outlined,
                color: AppColors.muted,
                size: 28,
              ),
            ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  final IconData icon;
  final String text;
  final String message;
  final VoidCallback? onRetry;

  const _StateMessage({
    required this.icon,
    required this.text,
    this.message = '',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (onRetry != null) return ErrorState(message: text, onRetry: onRetry);
    return EmptyState(icon: icon, title: text, message: message);
  }
}
