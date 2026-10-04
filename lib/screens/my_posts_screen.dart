import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/item_model.dart';
import '../providers/auth_provider.dart';
import '../providers/item_provider.dart';
import 'potential_matches_screen.dart';

class MyPostsScreen extends StatelessWidget {
  const MyPostsScreen({super.key});

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'lost':
        return Colors.red;
      case 'found':
        return Colors.green;
      case 'claimed':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'lost':
        return Icons.report_problem;
      case 'found':
        return Icons.check_circle;
      case 'claimed':
        return Icons.verified;
      case 'pending':
        return Icons.access_time;
      default:
        return Icons.help_outline;
    }
  }

  /// Claimed posts are already resolved, so there's nothing to match.
  bool _canCheckMatches(ItemModel item) {
    final status = item.status.toLowerCase();
    return status == 'lost' || status == 'found' || status == 'pending';
  }

  void showEditMessage(BuildContext context, ItemModel item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Edit "${item.title}" will be implemented later.',
        ),
      ),
    );
  }

  Future<void> confirmDelete(BuildContext context, ItemModel item) async {
    final itemProvider = context.read<ItemProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Delete Post"),
          content: Text('Delete "${item.title}"? This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Delete"),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${item.title}" was deleted.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider>().user?.uid;
    final itemProvider = context.watch<ItemProvider>();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: const Text(
          "My Posts",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: uid == null
          ? const Center(child: Text("Please sign in to view your posts."))
          : Column(
        children: [
          // FILTERS
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(
              children: [
                _buildFilterChip(context, itemProvider, "All"),
                _buildFilterChip(context, itemProvider, "Lost"),
                _buildFilterChip(context, itemProvider, "Found"),
                _buildFilterChip(context, itemProvider, "Claimed"),
              ],
            ),
          ),

          // POSTS
          Expanded(
            child: itemProvider.isLoadingMine
                ? const Center(child: CircularProgressIndicator())
                : Builder(builder: (context) {
              final items = itemProvider.myPosts;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Text(
                          "${items.length} post${items.length == 1 ? '' : 's'}",
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: itemProvider.refreshHome,
                      child: items.isEmpty
                          ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [_buildEmptyState()],
                      )
                          : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          16,
                          8,
                          16,
                          20,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return _buildPostCard(context, item);
                        },
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
      BuildContext context,
      ItemProvider itemProvider,
      String filter,
      ) {
    final isSelected = itemProvider.myPostsFilter == filter;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(filter),
        selected: isSelected,
        onSelected: (_) => itemProvider.setMyPostsFilter(filter),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w600,
        ),
        selectedColor: Colors.blue,
        backgroundColor: Colors.white,
        side: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  Widget _buildPostCard(BuildContext context, ItemModel item) {
    final statusColor = getStatusColor(item.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildItemImage(item),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.category,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.location,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 15,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.date,
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // SYNC STATUS (waiting for internet connection)
            if (item.isSyncPending)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.orange,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Waiting for internet connection to sync...',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // CHECK MATCHES
            if (_canCheckMatches(item)) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PotentialMatchesScreen(
                          itemId: item.id,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.manage_search),
                  label: Text(
                    item.status.toLowerCase() == 'lost'
                        ? 'Check for Found Matches'
                        : 'Check for Lost Matches',
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            const Divider(),
            const SizedBox(height: 4),

            const Divider(),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        getStatusIcon(item.status),
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        item.status.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: "Edit",
                  onPressed: () => showEditMessage(context, item),
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 21,
                  ),
                ),
                IconButton(
                  tooltip: "Delete",
                  onPressed: () => confirmDelete(context, item),
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 21,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemImage(ItemModel item) {
    final localPath = item.localImagePath;
    if (item.imageUrl.isEmpty && localPath != null && localPath.isNotEmpty) {
      return Image.file(
        File(localPath),
        width: 90,
        height: 90,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildImagePlaceholder(),
      );
    }

    if (item.imageUrl.isEmpty) {
      return _buildImagePlaceholder();
    }

    return Image.network(
      item.imageUrl,
      width: 90,
      height: 90,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 90,
      height: 90,
      color: Colors.grey.shade200,
      child: Icon(
        Icons.image_outlined,
        size: 40,
        color: Colors.grey.shade500,
      ),
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
              Icons.assignment_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 20),
            const Text(
              "No posts found",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "You don't have any posts in this category.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}