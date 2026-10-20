import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// "Oct 27 at 3:05 PM" (local time).
String formatSuspensionEnd(DateTime until) {
  final hour = until.hour == 0
      ? 12
      : (until.hour > 12 ? until.hour - 12 : until.hour);
  final minute = until.minute.toString().padLeft(2, '0');
  return '${_months[until.month - 1]} ${until.day} at $hour:$minute '
      '${until.hour >= 12 ? 'PM' : 'AM'}';
}

/// Tells a suspended user why they can't post and when they can again.
Future<void> showSuspendedDialog(BuildContext context, DateTime until) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.block_rounded, color: AppColors.lost, size: 32),
      title: const Text('Posting suspended'),
      content: Text(
        'An admin suspended your account from posting after a rule '
        'violation. You can report items again on '
        '${formatSuspensionEnd(until)}.\n\n'
        'You can still browse posts, message people and claim items.',
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

/// Full-screen version, shown if the report screen is opened anyway.
class SuspendedView extends StatelessWidget {
  final DateTime until;
  const SuspendedView({super.key, required this.until});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report item')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.lost.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.block_rounded,
                  size: 34,
                  color: AppColors.lost,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Posting suspended',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'You can report items again on '
                '${formatSuspensionEnd(until)}.\n'
                'You can still browse posts, message people and claim '
                'items.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, height: 1.4),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.maybePop(context),
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
