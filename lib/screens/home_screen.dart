import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/item_category.dart';
import '../providers/item_provider.dart';
import '../services/suspension_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_feedback.dart';
import '../widgets/category_card.dart';
import '../widgets/item_card.dart';
import '../widgets/item_ui.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/suspension_notice.dart';
import 'report_item_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});


  /// One plain sentence per tab so first-time users know what they're
  /// looking at.
  static const Map<String, String> _tabHints = {
    'All': 'Everything people have reported, newest first.',
    'Lost': 'Things people lost. Seen one? Message them.',
    'Found': 'Things people found. Is one yours? Tap it to claim.',
  };

  Future<void> _report(BuildContext context) async {
    // Suspended users can't post (enforced by Firestore rules too), so
    // explain why up front instead of letting them fill in the form.
    final suspendedUntil = await SuspensionService().activeSuspensionEnd();
    if (!context.mounted) return;
    if (suspendedUntil != null) {
      await showSuspendedDialog(context, suspendedUntil);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReportItemScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ItemProvider>();
    final items = provider.homeItems;
    final isLoading = provider.isLoadingAll;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        tooltip: 'Report a lost or found item',
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Report item',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5),
        ),
        onPressed: () => _report(context),
      ),
      body: RefreshIndicator(
        onRefresh: provider.refreshHome,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Title hides while scrolling down, returns on scroll up.
            const SliverAppBar(
              floating: true,
              snap: true,
              titleSpacing: 20,
              title: Text('FoundIt'),
            ),

            // SEARCH
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: SearchBarWidget(
                  query: provider.searchQuery,
                  onChanged: provider.setSearchQuery,
                ),
              ),
            ),

            // LOST / FOUND + what it means
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SegmentedTabs(
                      options: const ['All', 'Lost', 'Found'],
                      selected: provider.selectedStatus,
                      onChanged: provider.setSelectedStatus,
                    ),
                    const SizedBox(height: 10),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Row(
                        key: ValueKey(provider.selectedStatus),
                        children: [
                          Icon(
                            provider.selectedStatus == 'All'
                                ? Icons.info_outline_rounded
                                : statusIcon(provider.selectedStatus),
                            size: 18,
                            color: provider.selectedStatus == 'All'
                                ? AppColors.muted
                                : statusColor(provider.selectedStatus),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _tabHints[provider.selectedStatus] ?? '',
                              style: TextStyle(
                                fontSize: 14.5,
                                height: 1.35,
                                color: AppColors.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // CATEGORIES
            SliverToBoxAdapter(
              child: SizedBox(
                height: 68,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  itemCount: ItemCategory.all.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final category = ItemCategory.all[index];
                    return CategoryCard(
                      icon: category.icon,
                      title: category.name,
                      color: category.color,
                      isSelected: provider.selectedCategory == category.name,
                      onTap: () =>
                          provider.toggleSelectedCategory(category.name),
                    );
                  },
                ),
              ),
            ),

            // RESULT COUNT + CLEAR
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
                child: SizedBox(
                  height: 44,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          provider.hasActiveHomeFilters
                              ? '${items.length} '
                                  'result${items.length == 1 ? '' : 's'}'
                              : 'Latest posts',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (provider.hasActiveHomeFilters)
                        TextButton.icon(
                          onPressed: provider.clearHomeFilters,
                          icon: const Icon(Icons.close_rounded, size: 18),
                          label: const Text('Clear filters'),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // FEED
            if (isLoading && items.isEmpty)
              const SliverToBoxAdapter(child: FeedSkeleton())
            else if (items.isEmpty)
              SliverToBoxAdapter(
                child: EmptyState(
                  icon: provider.hasActiveHomeFilters
                      ? Icons.search_off_rounded
                      : Icons.inventory_2_outlined,
                  title: provider.hasActiveHomeFilters
                      ? 'No items match'
                      : 'No posts yet',
                  message: provider.hasActiveHomeFilters
                      ? 'Try a different word, or clear the filters.'
                      : 'Be the first! Lost and found items will show '
                          'up here.',
                  actionLabel: provider.hasActiveHomeFilters
                      ? 'Clear filters'
                      : 'Report an item',
                  onAction: provider.hasActiveHomeFilters
                      ? provider.clearHomeFilters
                      : () => _report(context),
                ),
              )
            else
              SliverList.builder(
                itemCount: items.length,
                itemBuilder: (context, index) => ItemCard(item: items[index]),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ),
      ),
    );
  }
}

