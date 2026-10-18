import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/item_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_feedback.dart';
import '../widgets/category_card.dart';
import '../widgets/item_card.dart';
import '../widgets/item_ui.dart';
import '../widgets/search_bar_widget.dart';
import 'report_item_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const List<_Category> _categories = [
    _Category('Electronics', Icons.phone_android_rounded, Color(0xFF2F5BEA)),
    _Category('Wallet', Icons.account_balance_wallet_rounded, Color(0xFFE08A00)),
    _Category('ID', Icons.badge_rounded, Color(0xFF1F9D68)),
    _Category('Keys', Icons.key_rounded, Color(0xFFE5484D)),
    _Category('Books', Icons.menu_book_rounded, Color(0xFF7C3AED)),
    _Category('Others', Icons.category_rounded, Color(0xFF0891B2)),
  ];

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
          'New post',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ReportItemScreen()),
          );
        },
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
              title: Text('Campus Lost & Found'),
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

            // LOST / FOUND
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: SegmentedTabs(
                  options: const ['All', 'Lost', 'Found'],
                  selected: provider.selectedStatus,
                  onChanged: provider.setSelectedStatus,
                ),
              ),
            ),

            // CATEGORIES
            SliverToBoxAdapter(
              child: SizedBox(
                height: 64,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  itemCount: _categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final category = _categories[index];
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

            // RESULT COUNT + CLEAR (only while filtering)
            if (provider.hasActiveHomeFilters)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 12, 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${items.length} result${items.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: provider.clearHomeFilters,
                        child: const Text('Clear filters'),
                      ),
                    ],
                  ),
                ),
              ),

            // FEED
            if (isLoading && items.isEmpty)
              const SliverToBoxAdapter(child: FeedSkeleton())
            else if (items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: provider.hasActiveHomeFilters
                      ? Icons.search_off_rounded
                      : Icons.inventory_2_outlined,
                  title: provider.hasActiveHomeFilters
                      ? 'No items match'
                      : 'No reports yet',
                  message: provider.hasActiveHomeFilters
                      ? 'Try a different word, or clear the filters.'
                      : 'Lost and found items will show up here.',
                  actionLabel: provider.hasActiveHomeFilters
                      ? 'Clear filters'
                      : 'Report an item',
                  onAction: provider.hasActiveHomeFilters
                      ? provider.clearHomeFilters
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ReportItemScreen(),
                            ),
                          ),
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

class _Category {
  final String name;
  final IconData icon;
  final Color color;

  const _Category(this.name, this.icon, this.color);
}
