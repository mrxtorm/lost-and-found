import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_tour.dart';
import 'terms_screen.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const _faqs = [
    (
      'How do I report a lost or found item?',
      'On the Home tab tap New post, choose Lost or Found, then fill in '
          'the title, category, location and date. Photos are optional for '
          'lost items but help others recognise it.',
    ),
    (
      'How do potential matches work?',
      'When a new post has a similar title, category or location to one of '
          'yours, the app suggests it as a potential match and sends you a '
          'notification. Open your post to see all suggested matches.',
    ),
    (
      'How do I claim an item that belongs to me?',
      'Open the found item and tap Claim item. Answer the verification question '
          'set by the finder. The finder reviews your claim and can approve '
          'or reject it. If rejected, you can resend the claim with more '
          'details.',
    ),
    (
      'How do I arrange the hand-over?',
      'Use the Message button on a post to chat with the other person. '
          'Meet in a public place on campus, such as the guard house or '
          'student affairs office.',
    ),
    (
      'Can I use the app without internet?',
      'Yes. Posts, messages and notifications you have already loaded stay '
          'available offline. New posts and messages are queued and sent '
          'automatically once you are back online.',
    ),
    (
      'How do I delete my post?',
      'Go to the My Posts tab, open the menu on the post and choose Delete. '
          'Use the filter at the top to see only Lost, Found or Archived posts.',
    ),
    (
      'I got my lost item back. What now?',
      'Open the chat with the person who returned it and tap "I got it '
          'back", or choose "Mark as claimed" from the menu in My Posts. '
          'The post moves to your Archive, where you can undo it for 7 days '
          'in case the handover falls through. After that, the post and its '
          'chat are deleted.',
    ),
    (
      'What happens if I report a post or message?',
      'Reports are reviewed by campus admins. Content that breaks the Terms '
          'of Service may be removed, and repeated offenses can lead to a '
          'temporary posting ban.',
    ),
    (
      'I forgot my password. What should I do?',
      'On the login screen tap "Forgot Password?" and enter your email. A '
          'reset link will be sent to your inbox.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const Text(
            'Frequently Asked Questions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            elevation: 0,
            color: AppColors.surface,
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Column(
              children: [
                for (var i = 0; i < _faqs.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  ExpansionTile(
                    shape: const Border(),
                    collapsedShape: const Border(),
                    leading: const Icon(
                      Icons.help_outline,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      _faqs[i].$1,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _faqs[i].$2,
                        style: TextStyle(color: AppColors.muted, height: 1.4),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const Text(
            'More',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            elevation: 0,
            color: AppColors.surface,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.explore_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text('App tour'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => AppTour.replay(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.description_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text('Terms of Service'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TermsScreen()),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.tips_and_updates_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text('Safety tips'),
                  subtitle: Text(
                    'Meet in public, never share passwords, and ask for '
                    'proof of ownership before handing over valuables.',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
