import 'dart:io';

import 'package:flutter/material.dart';

import '../models/item_model.dart';
import '../theme/app_theme.dart';

/// 'Lost' or 'Found'. Pending/Claimed items are publicly Found items.
String publicTypeOf(ItemModel item) =>
    item.status.toLowerCase() == 'lost' ? 'Lost' : 'Found';

Color statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'lost':
      return AppColors.lost;
    case 'found':
      return AppColors.found;
    case 'claimed':
      return AppColors.primary;
    case 'pending':
      return AppColors.warn;
    default:
      return AppColors.muted;
  }
}

/// "Just now", "5m ago", "3h ago", "2d ago", then the plain date.
String timeAgo(DateTime? time) {
  if (time == null) return '';
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${time.month}/${time.day}/${time.year}';
}

/// The best available photo for an item (uploaded one, else the local
/// offline copy), or null when the post has no photo.
ImageProvider? itemImageProvider(ItemModel item) {
  if (item.imageUrl.isNotEmpty) return NetworkImage(item.imageUrl);
  final path = item.localImagePath;
  if (path != null && path.isNotEmpty) return FileImage(File(path));
  return null;
}

class ImagePlaceholder extends StatelessWidget {
  const ImagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.track,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 40,
          color: Color(0xFFA3AAB8),
        ),
      ),
    );
  }
}

/// Fills its parent with the item's photo and fades it in when loaded.
class ItemImage extends StatelessWidget {
  final ItemModel item;
  final BoxFit fit;

  const ItemImage({super.key, required this.item, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    final provider = itemImageProvider(item);
    if (provider == null) return const ImagePlaceholder();

    return ColoredBox(
      color: AppColors.track,
      child: Image(
        image: provider,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            child: child,
          );
        },
        errorBuilder: (_, _, _) => const ImagePlaceholder(),
      ),
    );
  }
}

/// Circle with the user's initial, in a colour picked from their name.
class UserAvatar extends StatelessWidget {
  final String name;
  final double size;

  const UserAvatar({super.key, required this.name, this.size = 40});

  static const _palette = [
    Color(0xFF2F5BEA),
    Color(0xFF7C3AED),
    Color(0xFFDB2777),
    Color(0xFF0891B2),
    Color(0xFFD97706),
    Color(0xFF059669),
  ];

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final initial = trimmed.isEmpty
        ? '?'
        : String.fromCharCode(trimmed.runes.first).toUpperCase();
    final seed = trimmed.codeUnits.fold<int>(0, (sum, c) => sum + c);
    final color = _palette[seed % _palette.length];

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        shape: BoxShape.circle,
      ),
      child: Text(
        initial,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.42,
        ),
      ),
    );
  }
}

/// Small tinted pill with a dot: Lost, Found, Claimed, Pending.
class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final bool large;

  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 12 : 10,
        vertical: large ? 7 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: large ? 13 : 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// iOS-style segmented control (replaces the row of choice chips).
class SegmentedTabs extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;

  const SegmentedTabs({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.track,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(option),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: option == selected
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: option == selected
                        ? const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 6,
                        offset: Offset(0, 1),
                      ),
                    ]
                        : const [],
                  ),
                  child: Text(
                    option,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: option == selected
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: option == selected
                          ? AppColors.ink
                          : AppColors.muted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}