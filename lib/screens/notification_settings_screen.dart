import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/notification_provider.dart';
import '../services/notification_preferences_service.dart';
import '../theme/app_theme.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  static const _icons = {
    NotificationCategory.matches: Icons.auto_awesome_outlined,
    NotificationCategory.claims: Icons.assignment_turned_in_outlined,
    NotificationCategory.messages: Icons.chat_bubble_outline,
  };

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Notification Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Choose which notifications appear in your Notifications tab and '
            'count toward its badge. Settings are saved on this device.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.lg),
          Card(
            elevation: 0,
            color: AppColors.surface,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Column(
              children: [
                for (final category in NotificationCategory.values)
                  SwitchListTile(
                    secondary: Icon(_icons[category], color: AppColors.primary),
                    title: Text(
                      category.label,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      category.description,
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                    value: provider.isCategoryEnabled(category),
                    onChanged: (enabled) =>
                        provider.setCategoryEnabled(category, enabled),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.shield_outlined, size: 18, color: AppColors.muted),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Notices from admins about your posts or messages are '
                  'always shown.',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
