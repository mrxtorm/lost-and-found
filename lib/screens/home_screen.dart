import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/item_provider.dart';
import '../widgets/category_card.dart';
import '../widgets/item_card.dart';
import '../widgets/search_bar_widget.dart';
import 'item_details_screen.dart';
import 'messages_screen.dart';
import 'report_item_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final itemProvider = context.watch<ItemProvider>();
    final items = itemProvider.homeItems;
    final isLoading = itemProvider.isLoadingAll;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      // =========================
      // APP BAR
      // =========================
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: const Text(
          "Campus Lost & Found",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none,
              color: Colors.black87,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(
              Icons.account_circle,
              color: Colors.black87,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MessagesScreen(),
                ),
              );
            },
          ),
        ],
      ),

      // =========================
      // REPORT ITEM BUTTON
      // =========================
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ReportItemScreen(),
            ),
          );
        },
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),

      // =========================
      // BODY
      // =========================
      body: RefreshIndicator(
        onRefresh: itemProvider.refreshHome,
        child: ListView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            // SEARCH BAR
            SearchBarWidget(
              onChanged: (value) => itemProvider.setSearchQuery(value),
            ),

            const SizedBox(height: 20),

            // CATEGORIES
            const Text(
              "Categories",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  CategoryCard(
                    icon: Icons.phone_android,
                    title: "Electronics",
                    color: Colors.blue,
                    isSelected: itemProvider.selectedCategory == "Electronics",
                    onTap: () => itemProvider.toggleSelectedCategory("Electronics"),
                  ),
                  const SizedBox(width: 12),
                  CategoryCard(
                    icon: Icons.account_balance_wallet,
                    title: "Wallet",
                    color: Colors.orange,
                    isSelected: itemProvider.selectedCategory == "Wallet",
                    onTap: () => itemProvider.toggleSelectedCategory("Wallet"),
                  ),
                  const SizedBox(width: 12),
                  CategoryCard(
                    icon: Icons.badge,
                    title: "ID",
                    color: Colors.green,
                    isSelected: itemProvider.selectedCategory == "ID",
                    onTap: () => itemProvider.toggleSelectedCategory("ID"),
                  ),
                  const SizedBox(width: 12),
                  CategoryCard(
                    icon: Icons.key,
                    title: "Keys",
                    color: Colors.red,
                    isSelected: itemProvider.selectedCategory == "Keys",
                    onTap: () => itemProvider.toggleSelectedCategory("Keys"),
                  ),
                  const SizedBox(width: 12),
                  CategoryCard(
                    icon: Icons.book,
                    title: "Books",
                    color: Colors.purple,
                    isSelected: itemProvider.selectedCategory == "Books",
                    onTap: () => itemProvider.toggleSelectedCategory("Books"),
                  ),
                  const SizedBox(width: 12),
                  CategoryCard(
                    icon: Icons.category,
                    title: "Others",
                    color: Colors.teal,
                    isSelected: itemProvider.selectedCategory == "Others",
                    onTap: () => itemProvider.toggleSelectedCategory("Others"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // RECENT ITEMS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Recent Items",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${items.length} item${items.length == 1 ? '' : 's'}",
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),
            const SizedBox(height: 10),

            // STATUS FILTER
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatusFilter(context, itemProvider, "All"),
                  _buildStatusFilter(context, itemProvider, "Lost"),
                  _buildStatusFilter(context, itemProvider, "Found"),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ACTIVE FILTER INFO
            if (itemProvider.hasActiveHomeFilters)
              Container(
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.filter_alt_outlined,
                      size: 18,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getFilterDescription(itemProvider),
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: itemProvider.clearHomeFilters,
                      child: const Text(
                        "Clear",
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ITEMS
            if (isLoading && items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (items.isEmpty)
              _buildEmptyState()
            else
              ListView.builder(
                itemCount: items.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ItemCard(
                    item: item,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ItemDetailsScreen(item: item),
                        ),
                      );
                    },
                  );
                },
              ),

            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilter(
      BuildContext context,
      ItemProvider itemProvider,
      String status,
      ) {
    final isSelected = itemProvider.selectedStatus == status;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(status),
        selected: isSelected,
        onSelected: (_) => itemProvider.setSelectedStatus(status),
        selectedColor: Colors.blue,
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  String _getFilterDescription(ItemProvider itemProvider) {
    final filters = <String>[];

    if (itemProvider.searchQuery.isNotEmpty) {
      filters.add('Search: "${itemProvider.searchQuery}"');
    }
    if (itemProvider.selectedStatus != "All") {
      filters.add("Status: ${itemProvider.selectedStatus}");
    }
    if (itemProvider.selectedCategory != "All") {
      filters.add("Category: ${itemProvider.selectedCategory}");
    }

    return filters.join(" • ");
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: 70,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            "No items found",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Try a different search or filter.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}