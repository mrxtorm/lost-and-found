import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/item_model.dart';
import '../providers/auth_provider.dart';
import '../providers/item_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_feedback.dart';
import '../widgets/claim_actions.dart';
import '../widgets/item_ui.dart';
import 'edit_post_screen.dart';
import 'item_details_screen.dart';
import 'potential_matches_screen.dart';

class MyPostsScreen extends StatelessWidget {
  const MyPostsScreen({super.key});

  /// Claimed posts are already resolved, so there's nothing to match.
  bool _canCheckMatches(ItemModel item) {
    final status = item.status.toLowerCase();
    return status == 'lost' || status == 'found' || status == 'pending';
  }

  void openEdit(BuildContext context, ItemModel item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditPostScreen(item: item)),
    );
  }

  Future<void> confirmDelete(BuildContext context, ItemModel item) async {
    final itemProvider = context.read<ItemProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete post'),
          content: Text('Delete "${item.title}"? This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.lost),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    try {
      await itemProvider.deleteItem(item.id);
      if (!context.mounted) return;
      AppSnack.show(context, '"${item.title}" was deleted.', kind: SnackKind.success);
    } catch (e) {
      if (!context.mounted) return;
      AppSnack.show(context, 'Failed to delete: $e', kind: SnackKind.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider>().user?.uid;
    final itemProvider = context.watch<ItemProvider>();
    final items = itemProvider.myPosts;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: const Text('My posts'),
      ),
      body: uid == null
          ? const EmptyState(
              icon: Icons.lock_outline_rounded,
              title: 'Sign in required',
              message: 'Sign in to see your posts.',
            )
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: SegmentedTabs(
              options: const ['All', 'Lost', 'Found', 'Archived'],
              selected: itemProvider.myPostsFilter,
              onChanged: itemProvider.setMyPostsFilter,
            ),
          ),
          Expanded(
            child: itemProvider.isLoadingMine
                ? const LoadingView(label: 'Loading your posts')
                : RefreshIndicator(
              onRefresh: itemProvider.refreshHome,
              child: items.isEmpty
                  ? ListView(
                physics:
                const AlwaysScrollableScrollPhysics(),
                children: [
                  _buildEmptyState(
                    itemProvider.myPostsFilter,
                  ),
                ],
              )
                  : ListView.builder(
                physics:
                const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  24,
                ),
                itemCount: items.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(
                        4,
                        0,
                        4,
                        10,
                      ),
                      child: Text(
                        '${items.length} post${items.length == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }
                  return _buildPostCard(
                    context,
                    items[index - 1],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(BuildContext context, ItemModel item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ItemDetailsScreen(item: item),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        width: 92,
                        height: 92,
                        child: ItemImage(item: item),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    item.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.w800,
                                      height: 1.2,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 32,
                                height: 32,
                                child: PopupMenuButton<String>(
                                  padding: EdgeInsets.zero,
                                  icon: Icon(
                                    Icons.more_horiz_rounded,
                                    color: AppColors.muted,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'edit':
                                        openEdit(context, item);
                                      case 'claimed':
                                        ClaimActions.markReturned(
                                          context,
                                          item,
                                        );
                                      case 'undo':
                                        ClaimActions.undo(context, item);
                                      default:
                                        confirmDelete(context, item);
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    if (item.isClaimed)
                                      const PopupMenuItem(
                                        value: 'undo',
                                        child: Text('Undo claim'),
                                      )
                                    else
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Edit'),
                                      ),
                                    if (item.status.toLowerCase() == 'lost')
                                      const PopupMenuItem(
                                        value: 'claimed',
                                        child: Text('Mark as claimed'),
                                      ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text(
                                        'Delete',
                                        style: TextStyle(
                                          color: AppColors.lost,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          _metaRow(Icons.location_on_outlined, item.location),
                          const SizedBox(height: 2),
                          _metaRow(Icons.calendar_today_outlined, item.date),
                          const SizedBox(height: 8),
                          StatusPill(
                            label: item.status,
                            color: statusColor(item.status),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Waiting to sync
                if (item.isSyncPending) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warn.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 13,
                          height: 13,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.warn,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Waiting for internet to sync',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.warn,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Archived: who it went to, when it's deleted, undo
                if (item.isClaimed) ...[
                  const SizedBox(height: 12),
                  _buildArchiveBanner(context, item),
                ],

                // Check matches
                if (_canCheckMatches(item)) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                PotentialMatchesScreen(itemId: item.id),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        backgroundColor:
                        AppColors.primary.withValues(alpha: 0.08),
                        foregroundColor: AppColors.primary,
                      ),
                      icon: const Icon(Icons.manage_search_rounded, size: 20),
                      label: Text(
                        item.status.toLowerCase() == 'lost'
                            ? 'Check for found matches'
                            : 'Check for lost matches',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArchiveBanner(BuildContext context, ItemModel item) {
    final other = item.claimedByName ?? '';
    final who = other.isEmpty
        ? 'Marked as claimed'
        : item.statusBeforeClaim == 'Found'
            ? 'Claimed by $other'
            : 'Returned by $other';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  who,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  ClaimActions.deletesInLabel(item),
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => ClaimActions.undo(context, item),
            child: const Text('Undo'),
          ),
        ],
      ),
    );
  }

  Widget _metaRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.muted),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: AppColors.muted),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String filter) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: EmptyState(
        icon: Icons.assignment_outlined,
        title: 'Nothing here yet',
        message: filter == 'All'
            ? 'Posts you create will show up here.'
            : filter == 'Archived'
                ? 'Claimed posts wait here for '
                    '${ItemModel.archiveDays} days before they are deleted.'
                : 'You have no ${filter.toLowerCase()} posts.',
      ),
    );
  }
}
