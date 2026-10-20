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
import 'app_tour.dart';
import 'report_item_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// One plain sentence per tab so first-time users know what they're
  /// looking at.
  static const Map<String, String> _tabHints = {
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
        key: AppTour.reportButtonKey,
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
                  key: AppTour.searchKey,
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
                      key: AppTour.statusTabsKey,
                      options: const ['All', 'Lost', 'Found'],
                      selected: provider.selectedStatus,
                      onChanged: provider.setSelectedStatus,
                    ),
                    // No hint for All: the feed speaks for itself.
                    AnimatedSize(
                      duration: const Duration(milliseconds: 180),
                      alignment: Alignment.topCenter,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: provider.selectedStatus == 'All'
                            ? const SizedBox(width: double.infinity)
                            : Padding(
                                key: ValueKey(provider.selectedStatus),
                                padding: const EdgeInsets.only(top: 10),
                                child: Row(
                                  children: [
                                    Icon(
                                      statusIcon(provider.selectedStatus),
                                      size: 18,
                                      color: statusColor(
                                        provider.selectedStatus,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _tabHints[provider.selectedStatus] ??
                                            '',
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
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // CATEGORIES
            SliverToBoxAdapter(
              child: _CategoryStrip(
                key: AppTour.categoriesKey,
                selected: provider.selectedCategory,
                onToggle: provider.toggleSelectedCategory,
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
                itemBuilder: (context, index) => ItemCard(
                  // The top post is highlighted by the app tour.
                  key: index == 0 ? AppTour.firstPostKey : null,
                  item: items[index],
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ),
      ),
    );
  }
}

/// Horizontally scrolling category chips. Faded edges with arrow buttons
/// show there are more categories off screen; each arrow hides once that
/// end is reached, and tapping it scrolls further.
class _CategoryStrip extends StatefulWidget {
  final String? selected;
  final ValueChanged<String> onToggle;

  const _CategoryStrip({
    super.key,
    required this.selected,
    required this.onToggle,
  });

  @override
  State<_CategoryStrip> createState() => _CategoryStripState();
}

class _CategoryStripState extends State<_CategoryStrip> {
  final ScrollController _controller = ScrollController();
  bool _canScrollLeft = false;
  bool _canScrollRight = true;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateArrows);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateArrows());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateArrows() {
    if (!mounted || !_controller.hasClients) return;
    final pos = _controller.position;
    final left = pos.pixels > pos.minScrollExtent + 4;
    final right = pos.pixels < pos.maxScrollExtent - 4;
    if (left != _canScrollLeft || right != _canScrollRight) {
      setState(() {
        _canScrollLeft = left;
        _canScrollRight = right;
      });
    }
  }

  void _scrollBy(double delta) {
    final pos = _controller.position;
    _controller.animateTo(
      (pos.pixels + delta).clamp(pos.minScrollExtent, pos.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _arrow({required bool left, required bool visible}) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    return Positioned(
      top: 0,
      bottom: 0,
      left: left ? 0 : null,
      right: left ? null : 0,
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 180),
          child: Container(
            width: 56,
            alignment: left ? Alignment.centerLeft : Alignment.centerRight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: left ? Alignment.centerRight : Alignment.centerLeft,
                end: left ? Alignment.centerLeft : Alignment.centerRight,
                colors: [bg.withValues(alpha: 0), bg, bg],
                stops: const [0, 0.6, 1],
              ),
            ),
            child: IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: left ? 'Previous categories' : 'More categories',
              onPressed: () => _scrollBy(left ? -200 : 200),
              icon: Icon(
                left ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                color: AppColors.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 68,
      child: Stack(
        children: [
          ListView.separated(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            // Extra right padding so the last chip can scroll clear of the
            // arrow.
            padding: const EdgeInsets.fromLTRB(20, 12, 40, 12),
            itemCount: ItemCategory.all.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final category = ItemCategory.all[index];
              return CategoryCard(
                icon: category.icon,
                title: category.name,
                color: category.color,
                isSelected: widget.selected == category.name,
                onTap: () => widget.onToggle(category.name),
              );
            },
          ),
          _arrow(left: true, visible: _canScrollLeft),
          _arrow(left: false, visible: _canScrollRight),
        ],
      ),
    );
  }
}
