import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../services/conversation_loader.dart';
import 'conversation_screen.dart';

import '../data/local/app_database.dart';
import '../models/item_model.dart';
import '../models/notification_model.dart';
import '../providers/notification_provider.dart';
import 'item_details_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  IconData _iconFor(String type) {
    switch (type) {
      case NotificationType.match:
      case NotificationType.categoryMatch:
        return Icons.search;
      case NotificationType.claimReceived:
        return Icons.person_search;
      case NotificationType.claimApproved:
        return Icons.check_circle;
      case NotificationType.claimRejected:
        return Icons.cancel;
      case NotificationType.claimUpdate:
        return Icons.assignment_turned_in;
      case NotificationType.message:
        return Icons.chat_bubble;
      case NotificationType.reportPosted:
        return Icons.cloud_done;
      default:
        return Icons.notifications;
    }
  }

  Color _colorFor(String type) {
    switch (type) {
      case NotificationType.match:
      case NotificationType.categoryMatch:
        return Colors.green;
      case NotificationType.claimReceived:
        return Colors.purple;
      case NotificationType.claimApproved:
        return Colors.green;
      case NotificationType.claimRejected:
        return Colors.red;
      case NotificationType.claimUpdate:
        return Colors.blue;
      case NotificationType.message:
        return Colors.blue;
      case NotificationType.reportPosted:
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = context.watch<NotificationProvider>();
    final notifications = notificationProvider.notifications;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (notificationProvider.unreadCount > 0)
            TextButton(
              onPressed: () => notificationProvider.markAllAsRead(),
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: notificationProvider.refreshNotifications,
        child: notificationProvider.isLoading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  Padding(
                    padding: EdgeInsets.only(top: 120),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              )
            : notifications.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [_buildEmptyState()],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      return _buildNotificationCard(
                        context,
                        notificationProvider,
                        notifications[index],
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    NotificationProvider notificationProvider,
    NotificationModel notification,
  ) {
    final color = _colorFor(notification.type);

    return FutureBuilder<ItemRow?>(
      future: _relatedItem(context, notification),
      builder: (context, snapshot) {
        final item = snapshot.data;

        return GestureDetector(
          onTap: () => _handleTap(
            context,
            notificationProvider,
            notification,
            item,
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: notification.isRead ? Colors.white : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: notification.isRead
                    ? Colors.grey.shade200
                    : Colors.blue.shade100,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildItemImage(item, color),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: notification.isRead
                                      ? FontWeight.w600
                                      : FontWeight.bold,
                                ),
                              ),
                            ),
                            if (!notification.isRead)
                              Container(
                                width: 9,
                                height: 9,
                                margin:
                                    const EdgeInsets.only(left: 8, top: 5),
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          notification.message,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              _formatTime(notification.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            const Spacer(),
                            if (notification.relatedItemId != null)
                              Icon(
                                Icons.chevron_right,
                                size: 20,
                                color: Colors.grey.shade500,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // TAP HANDLING
  // ============================================================

  Future<void> _handleTap(
      BuildContext context,
      NotificationProvider notificationProvider,
      NotificationModel notification,
      ItemRow? cachedItem,
      ) async {
    if (!notification.isRead) {
      await notificationProvider.markAsRead(notification.id);
    }

    if (!context.mounted) return;

    switch (notification.type) {
    // Claim conversations: go straight to the chat.
      case NotificationType.claimReceived:
      case NotificationType.claimRejected:
      case NotificationType.claimUpdate:
        final opened = await _openConversation(
          context,
          notification,
          cachedItem,
        );
        if (opened) return;
        break;

    // Approved: the post and conversation were removed when the claim
    // was accepted, so there is nothing to open.
      case NotificationType.claimApproved:
        _showNotificationDetails(context, notification, null);
        return;

      default:
        break;
    }

    if (!context.mounted) return;
    await _openPost(context, notification, cachedItem);
  }

  /// Opens the related post. Uses the local cache first, then Firestore.
  Future<void> _openPost(
      BuildContext context,
      NotificationModel notification,
      ItemRow? cachedItem,
      ) async {
    ItemModel? model = cachedItem != null ? _rowToModel(cachedItem) : null;
    model ??= await _fetchItem(notification.relatedItemId);

    if (!context.mounted) return;

    if (model == null) {
      // Deleted, claimed, or not reachable right now.
      _showNotificationDetails(context, notification, null);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ItemDetailsScreen(item: model!)),
    );
  }

  /// Opens the claim conversation between the current user and the other
  /// person. Returns false if it can't be opened (caller falls back to
  /// the post).
  Future<bool> _openConversation(
      BuildContext context,
      NotificationModel notification,
      ItemRow? cachedItem,
      ) async {
    final me = context.read<AuthProvider>().user?.uid;
    final chat = context.read<ChatProvider>();
    final itemId = notification.relatedItemId;

    if (me == null || itemId == null || itemId.isEmpty) return false;

    final otherId = await _otherParticipantId(
      notification,
      itemId,
      cachedItem,
    );
    if (otherId == null || otherId.isEmpty || otherId == me) return false;

    // Same id format ChatService.getOrCreateConversation uses.
    final ids = [me, otherId]..sort();
    final conversationId = '${itemId}_${ids.join('_')}';

    if (chat.conversationById(conversationId) == null) {
      final result = await ConversationLoader().load(conversationId);

      // Gone (e.g. claim already resolved) or not ours: use the fallback.
      // Other errors (such as being offline) still try to open the chat.
      if (result.status == ConversationLoadStatus.notFound ||
          result.status == ConversationLoadStatus.forbidden) {
        return false;
      }
    }

    if (!context.mounted) return false;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConversationScreen(conversationId: conversationId),
      ),
    );
    return true;
  }

  /// Works out who is on the other side of the conversation.
  Future<String?> _otherParticipantId(
      NotificationModel notification,
      String itemId,
      ItemRow? cachedItem,
      ) async {
    // The finder was notified: the other person is the claimant, whose uid
    // is the tail of the claim id ("{itemId}_{claimantUid}").
    if (notification.type == NotificationType.claimReceived) {
      final claimId = notification.relatedClaimId ?? '';
      final prefix = '${itemId}_';
      if (claimId.startsWith(prefix)) {
        return claimId.substring(prefix.length);
      }
      return null;
    }

    // The claimant was notified: the other person is the item's finder.
    if (cachedItem != null && cachedItem.ownerId.isNotEmpty) {
      return cachedItem.ownerId;
    }

    final item = await _fetchItem(itemId);
    return item?.ownerId;
  }

  Future<ItemModel?> _fetchItem(String? itemId) async {
    if (itemId == null || itemId.isEmpty) return null;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('items')
          .doc(itemId)
          .get()
          .timeout(const Duration(seconds: 6));

      if (!doc.exists) return null;
      return ItemModel.fromDoc(doc);
    } catch (_) {
      return null;
    }
  }

  Future<ItemRow?> _relatedItem(
    BuildContext context,
    NotificationModel notification,
  ) {
    final itemId = notification.relatedItemId;
    if (itemId == null || itemId.isEmpty) {
      return Future.value(null);
    }

    return context.read<AppDatabase>().getItem(itemId);
  }

  Widget _buildItemImage(ItemRow? item, Color color) {
    if (item != null && item.imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          item.imageUrl,
          width: 76,
          height: 76,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _imagePlaceholder(color),
        ),
      );
    }

    if (item != null &&
        item.localImagePath != null &&
        item.localImagePath!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(item.localImagePath!),
          width: 76,
          height: 76,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _imagePlaceholder(color),
        ),
      );
    }

    return _imagePlaceholder(color);
  }

  Widget _imagePlaceholder(Color color) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.notifications,
        color: color,
        size: 28,
      ),
    );
  }

  ItemModel _rowToModel(ItemRow row) {
    return ItemModel(
      id: row.id,
      title: row.title,
      description: row.description,
      category: row.category,
      location: row.location,
      date: row.date,
      status: row.status,
      imageUrl: row.imageUrl,
      username: row.username,
      ownerId: row.ownerId,
      verificationQuestion: row.verificationQuestion,
      createdAt: row.createdAt,
      localImagePath: row.localImagePath,
      isSyncPending: row.pendingCreate || row.pendingUpdate,
    );
  }

  void _showNotificationDetails(
    BuildContext context,
    NotificationModel notification,
    ItemModel? item,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _colorFor(notification.type).withOpacity(.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _iconFor(notification.type),
                      color: _colorFor(notification.type),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      notification.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                notification.message,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _formatTime(notification.createdAt),
                style: TextStyle(color: Colors.grey.shade500),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Close',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 20),
            const Text(
              'No Notifications',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'You are all caught up!',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
