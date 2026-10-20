import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/item_model.dart';
import '../theme/app_theme.dart';

/// 'Lost' or 'Found'. Pending/Claimed items are publicly Found items.
String publicTypeOf(ItemModel item) =>
    item.status.toLowerCase() == 'lost' ? 'Lost' : 'Found';

IconData statusIcon(String status) {
  switch (status.toLowerCase()) {
    case 'lost':
      return Icons.search_rounded;
    case 'found':
      // An eye ("spotted"), not a check: a check reads as "returned".
      return Icons.visibility_outlined;
    case 'claimed':
      return Icons.verified_rounded;
    case 'pending':
      return Icons.hourglass_top_rounded;
    default:
      return Icons.circle;
  }
}

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
/// Asks Cloudinary for a resized, compressed copy instead of the original.
/// Works on already-uploaded photos because it only rewrites the URL.
String optimizedImageUrl(String url, {int width = 1000}) {
  const marker = '/image/upload/';
  if (!url.contains('res.cloudinary.com') ||
      !url.contains(marker) ||
      url.contains('q_auto')) {
    return url; // not Cloudinary, or already transformed
  }
  return url.replaceFirst(marker, '${marker}w_$width,c_limit,q_auto,f_auto/');
}

/// The best available photo for an item (uploaded one, else the local
/// offline copy), or null when the post has no photo.
ImageProvider? itemImageProvider(ItemModel item, {int width = 1000}) {
  final providers = itemImageProviders(item, width: width);
  return providers.isEmpty ? null : providers.first;
}

/// Every available photo for an item, in order: uploaded ones, else the
/// local offline copies. Empty when the post has no photos.
List<ImageProvider> itemImageProviders(ItemModel item, {int width = 1000}) {
  final urls = item.allImageUrls;
  if (urls.isNotEmpty) {
    return [
      for (final url in urls)
        CachedNetworkImageProvider(
          optimizedImageUrl(url, width: width),
          maxWidth: width,
        ),
    ];
  }
  return [
    for (final path in item.allLocalImagePaths)
      ResizeImage(FileImage(File(path)), width: width),
  ];
}

/// Instagram-style swipeable photo carousel. Falls back to a single image /
/// placeholder when the post has zero or one photo, and only shows the page
/// indicators when there is more than one.
class ItemImageCarousel extends StatefulWidget {
  final ItemModel item;
  final BoxFit fit;
  final int width;

  /// Called with the index of the photo that was tapped.
  final ValueChanged<int>? onTapPhoto;

  /// Distance of the photo counter (top/right) and page dots (bottom) from
  /// the edges, so callers can keep them clear of toolbars or overlays.
  final EdgeInsets overlayInsets;

  const ItemImageCarousel({
    super.key,
    required this.item,
    this.fit = BoxFit.cover,
    this.width = 800,
    this.onTapPhoto,
    this.overlayInsets = const EdgeInsets.fromLTRB(10, 10, 10, 8),
  });

  @override
  State<ItemImageCarousel> createState() => _ItemImageCarouselState();
}

class _ItemImageCarouselState extends State<ItemImageCarousel> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _page(ImageProvider provider) {
    return ColoredBox(
      color: AppColors.track,
      child: Image(
        image: provider,
        fit: widget.fit,
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

  @override
  Widget build(BuildContext context) {
    final providers = itemImageProviders(widget.item, width: widget.width);
    if (providers.isEmpty) return const ImagePlaceholder.noPhoto();

    final count = providers.length;
    final current = _index.clamp(0, count - 1);

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _controller,
          itemCount: count,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (context, i) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTapPhoto == null
                ? null
                : () => widget.onTapPhoto!(i),
            child: _page(providers[i]),
          ),
        ),
        if (count > 1) ...[
          Positioned(
            top: widget.overlayInsets.top,
            right: widget.overlayInsets.right,
            child: IgnorePointer(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${current + 1}/$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: widget.overlayInsets.bottom,
            child: IgnorePointer(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < count; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == current ? 8 : 6,
                      height: i == current ? 8 : 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == current
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.5),
                        boxShadow: const [
                          BoxShadow(color: Color(0x66000000), blurRadius: 3),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class ImagePlaceholder extends StatelessWidget {
  /// Optional caption under the icon, e.g. for posts with no photo attached.
  final String? label;

  const ImagePlaceholder({super.key, this.label});

  /// Shown when the post was created without any photo.
  const ImagePlaceholder.noPhoto({super.key}) : label = 'No photo attached';

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF8A93A3);
    if (label == null) {
      return ColoredBox(
        color: AppColors.track,
        child: Center(
          child: Icon(Icons.image_outlined, size: 40, color: color),
        ),
      );
    }
    return ColoredBox(
      color: AppColors.track,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.hide_image_outlined,
                  size: 40,
                  color: color,
                ),
                const SizedBox(height: 6),
                Text(
                  label!,
                  style: const TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
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
    final provider = itemImageProvider(item, width: 800);
    if (provider == null) return const ImagePlaceholder.noPhoto();

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

  /// Profile photo; falls back to the coloured initial when empty or while
  /// it fails to load.
  final String? photoUrl;
  final double size;

  const UserAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.size = 40,
  });

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

    final initialAvatar = Container(
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

    final url = photoUrl;
    if (url == null || url.isEmpty) return initialAvatar;
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, _) => initialAvatar,
        errorWidget: (_, _, _) => initialAvatar,
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
    return Semantics(
      label: 'Status: $label',
      excludeSemantics: true,
      child: Container(
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
            Icon(statusIcon(label), size: large ? 15 : 13, color: color),
            const SizedBox(width: 5),
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
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.track,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: Semantics(
                button: true,
                selected: option == selected,
                label: option,
                excludeSemantics: true,
                child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (option != selected) HapticFeedback.selectionClick();
                  onChanged(option);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: option == selected
                        ? AppColors.surface
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
            ),
        ],
      ),
    );
  }
}