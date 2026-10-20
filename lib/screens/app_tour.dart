import 'package:flutter/material.dart';

import '../models/item_model.dart';
import '../theme/app_theme.dart';
import '../widgets/spotlight_tour.dart';

/// Optional spotlight tour of FoundIt's main features.
///
/// The highlighted widgets carry the keys below. [MainNavigationScreen]
/// registers [_launcher] so the tour can be replayed from anywhere: it
/// switches to the Home tab first so every target is on screen.
class AppTour {
  AppTour._();

  static final searchKey = GlobalKey(debugLabel: 'tour-search');
  static final statusTabsKey = GlobalKey(debugLabel: 'tour-status-tabs');
  static final categoriesKey = GlobalKey(debugLabel: 'tour-categories');
  static final firstPostKey = GlobalKey(debugLabel: 'tour-first-post');
  static final reportButtonKey = GlobalKey(debugLabel: 'tour-report');
  static final navBarKey = GlobalKey(debugLabel: 'tour-nav-bar');

  /// Number of destinations in the bottom NavigationBar.
  static const _navCount = 5;

  static Future<void> Function()? _launcher;

  /// Called by the main navigation screen while it is mounted.
  static void register(Future<void> Function()? launcher) =>
      _launcher = launcher;

  /// Replays the tour, closing any screens pushed on top of the main one.
  static Future<void> replay(BuildContext context) async {
    Navigator.of(context).popUntil((route) => route.isFirst);
    await _launcher?.call();
  }

  /// Highlights one destination of the bottom navigation bar.
  static Rect Function(Rect) _navItem(int index) => (bar) {
    final width = bar.width / _navCount;
    // NavigationBar's own height is 80; the rest is the safe area inset.
    final height = bar.height < 80 ? bar.height : 80.0;
    return Rect.fromLTWH(
      bar.left + width * index,
      bar.top,
      width,
      height,
    ).deflate(4);
  };

  /// What to do with [post], depending on whether it was lost or found.
  static SpotlightStep _livePostStep(ItemModel post) {
    final name = '"${post.title}"';
    final description = switch (post.status.toLowerCase()) {
      'found' =>
        "Someone found $name. If it's yours, tap the post, press "
            "Claim item and answer the finder's question to prove it.",
      'lost' =>
        "Someone lost $name. If you've seen or found it, tap the "
            'post and press Message to let the owner know.',
      _ =>
        'Tap $name to see its photos, location and date, then claim it '
            'or message the poster.',
    };
    return SpotlightStep(
      targetKey: firstPostKey,
      icon: Icons.touch_app_outlined,
      title: 'This is a live post',
      description: description,
    );
  }

  /// Tour steps. [firstPost] is the top post in the Home feed, if any; it
  /// gets its own step explaining what to do with it.
  static List<SpotlightStep> steps({ItemModel? firstPost}) => [
    SpotlightStep(
      targetKey: searchKey,
      icon: Icons.search_rounded,
      title: 'Search for items',
      description:
          'Type a name, color or place to quickly find a lost '
          'or found item.',
      radius: 28,
    ),
    SpotlightStep(
      targetKey: statusTabsKey,
      icon: Icons.swap_horiz_rounded,
      title: 'Lost or found?',
      description:
          'Switch between items people lost and items people '
          'found. Spotted something that\'s yours? Open it and claim it.',
    ),
    SpotlightStep(
      targetKey: categoriesKey,
      icon: Icons.category_outlined,
      title: 'Filter by category',
      description:
          'Tap a category like Phones or Keys to narrow the '
          'feed. Tap it again to clear the filter.',
      radius: 20,
    ),
    if (firstPost != null) _livePostStep(firstPost),
    SpotlightStep(
      targetKey: reportButtonKey,
      icon: Icons.add_rounded,
      title: 'Report an item',
      description:
          'Lost something or found something? Post it here. '
          'FoundIt will notify you when a similar post shows up.',
      radius: 18,
    ),
    SpotlightStep(
      targetKey: navBarKey,
      rectOf: _navItem(1),
      icon: Icons.chat_bubble_outline,
      title: 'Messages',
      description:
          'Chat with finders and owners to arrange a safe '
          'hand-over somewhere public on campus.',
    ),
    SpotlightStep(
      targetKey: navBarKey,
      rectOf: _navItem(2),
      icon: Icons.assignment_outlined,
      title: 'My Posts',
      description:
          'Manage your reports, review claims on items you '
          'found, and mark items as returned.',
    ),
    SpotlightStep(
      targetKey: navBarKey,
      rectOf: _navItem(3),
      icon: Icons.notifications_outlined,
      title: 'Notifications',
      description:
          'Get alerted about potential matches, new claims and '
          'updates on your posts.',
    ),
    SpotlightStep(
      targetKey: navBarKey,
      rectOf: _navItem(4),
      icon: Icons.person_outline,
      title: 'Profile',
      description:
          'Edit your account, change the theme, get help, and '
          'replay this tour any time.',
    ),
  ];
}

/// Asks whether the user wants the tour. Returns true for "Show me around".
Future<bool> offerAppTour(BuildContext context) async {
  final accepted = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.explore_outlined, color: AppColors.primary),
      title: const Text('New to FoundIt?'),
      content: const Text(
        'Take a quick tour of the main features. It takes less than a '
        'minute, and you can replay it any time from Profile.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Not now'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Show me around'),
        ),
      ],
    ),
  );
  return accepted == true;
}
