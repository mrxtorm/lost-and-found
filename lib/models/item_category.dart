import 'package:flutter/material.dart';

/// One preset category a post can be filed under.
class ItemCategory {
  final String name;
  final IconData icon;
  final Color color;

  const ItemCategory(this.name, this.icon, this.color);

  /// Every preset, in the order shown on Home and in the post forms.
  static const List<ItemCategory> all = [
    ItemCategory('Phones', Icons.phone_android_rounded, Color(0xFF2F5BEA)),
    ItemCategory('Electronics', Icons.devices_rounded, Color(0xFF4F46E5)),
    ItemCategory('IDs & Cards', Icons.badge_rounded, Color(0xFF1F9D68)),
    ItemCategory(
      'Wallets & Purses',
      Icons.account_balance_wallet_rounded,
      Color(0xFFE08A00),
    ),
    ItemCategory('Keys', Icons.key_rounded, Color(0xFFE5484D)),
    ItemCategory('Bags', Icons.backpack_rounded, Color(0xFF9A5B2E)),
    ItemCategory('School Supplies', Icons.menu_book_rounded, Color(0xFF7C3AED)),
    ItemCategory('Clothing', Icons.checkroom_rounded, Color(0xFFDB2777)),
    ItemCategory('Accessories', Icons.watch_rounded, Color(0xFF0D9488)),
    ItemCategory('Others', Icons.category_rounded, Color(0xFF0891B2)),
  ];

  /// Names used by posts made before the category list was reworked.
  /// Those posts are never rewritten; they're read as the new name instead.
  static const Map<String, String> _legacy = {
    'Wallet': 'Wallets & Purses',
    'ID': 'IDs & Cards',
    'Books': 'School Supplies',
  };

  /// The current category name for [value], mapping old names onto new ones
  /// so filters, matching and display treat old and new posts the same.
  static String canonical(String value) {
    final key = value.trim().toLowerCase();
    for (final entry in _legacy.entries) {
      if (entry.key.toLowerCase() == key) return entry.value;
    }
    for (final category in all) {
      if (category.name.toLowerCase() == key) return category.name;
    }
    return value.trim();
  }

  /// Every stored name that means [value] (the current name plus any old
  /// one), for server-side queries that need exact matches.
  static List<String> storedNames(String value) {
    final name = canonical(value);
    return [
      name,
      for (final entry in _legacy.entries)
        if (entry.value == name) entry.key,
    ];
  }

  static ItemCategory? find(String value) {
    final name = canonical(value);
    for (final category in all) {
      if (category.name == name) return category;
    }
    return null;
  }
}
