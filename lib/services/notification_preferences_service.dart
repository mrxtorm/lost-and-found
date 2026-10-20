import 'package:shared_preferences/shared_preferences.dart';

import '../models/notification_model.dart';

/// Groups of notification types the user can mute from Profile >
/// Notification Settings. Moderation notices and local sync confirmations
/// are not in any group, so they can never be muted.
enum NotificationCategory {
  matches(
    'Potential matches',
    'When a new post looks like one of your items',
    [NotificationType.match, NotificationType.categoryMatch],
  ),
  claims(
    'Claims',
    'Claims on your posts and updates on your own claims',
    [
      NotificationType.claimReceived,
      NotificationType.claimApproved,
      NotificationType.claimRejected,
      NotificationType.claimUpdate,
    ],
  ),
  messages(
    'Messages',
    'New chat messages from other users',
    [NotificationType.message],
  );

  final String label;
  final String description;
  final List<String> types;

  const NotificationCategory(this.label, this.description, this.types);

  static NotificationCategory? forType(String type) {
    for (final category in values) {
      if (category.types.contains(type)) return category;
    }
    return null;
  }
}

/// Per-account, on-device notification preferences. Everything is enabled
/// by default; only muted categories are stored.
class NotificationPreferencesService {
  static String _key(String uid) => 'notification_muted_categories_$uid';

  Future<Set<NotificationCategory>> getMuted(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final names = prefs.getStringList(_key(uid)) ?? const [];
    return {
      for (final category in NotificationCategory.values)
        if (names.contains(category.name)) category,
    };
  }

  Future<void> setMuted(String uid, Set<NotificationCategory> muted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key(uid),
      muted.map((c) => c.name).toList(),
    );
  }
}
