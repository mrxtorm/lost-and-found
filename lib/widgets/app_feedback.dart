import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

enum SnackKind { success, error, info }

/// One consistent way to tell the user what happened.
///
/// Icon + colour + text, so meaning never relies on colour alone.
class AppSnack {
  AppSnack._();

  static void show(
    BuildContext context,
    String message, {
    SnackKind kind = SnackKind.info,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final (icon, color) = switch (kind) {
      SnackKind.success => (Icons.check_circle_rounded, AppColors.success),
      SnackKind.error => (Icons.error_rounded, AppColors.error),
      SnackKind.info => (Icons.info_rounded, const Color(0xFF9DB5FF)),
    };
    if (kind == SnackKind.error) HapticFeedback.mediumImpact();

    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: Duration(seconds: kind == SnackKind.error ? 5 : 3),
          content: Semantics(
            liveRegion: true,
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(message)),
              ],
            ),
          ),
          action: actionLabel == null
              ? null
              : SnackBarAction(
                  label: actionLabel,
                  onPressed: onAction ?? () {},
                ),
        ),
      );
  }

  static void success(BuildContext c, String m) =>
      show(c, m, kind: SnackKind.success);
  static void error(BuildContext c, String m) =>
      show(c, m, kind: SnackKind.error);
  static void info(BuildContext c, String m) => show(c, m);
}

/// One consistent "Are you sure?" dialog. Resolves to true only when the
/// user taps [confirmLabel]; Cancel, back and tapping outside are "no".
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
  IconData? icon,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: icon == null
          ? null
          : Icon(icon, color: destructive ? AppColors.error : null),
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(backgroundColor: AppColors.error)
              : null,
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return confirmed == true;
}

/// Friendly text for an exception; avoids showing "Exception: ..." dumps.
String friendlyError(Object e) {
  final text = e.toString().replaceFirst(RegExp(r'^(Exception|Error): '), '');
  final lower = text.toLowerCase();
  if (lower.contains('network') ||
      lower.contains('socket') ||
      lower.contains('unavailable')) {
    return 'No connection. Check your internet and try again.';
  }
  return text;
}

/// Centred icon + title + message + optional action. Used for empty lists.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color color;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ExcludeSemantics(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: color),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, height: 1.4),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

/// Error with a retry button.
class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorState({
    super.key,
    this.message = 'Something went wrong. Please try again.',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.cloud_off_rounded,
      color: AppColors.error,
      title: 'Couldn\'t load this',
      message: message,
      actionLabel: onRetry == null ? null : 'Try again',
      onAction: onRetry,
    );
  }
}

/// Centred spinner with an optional caption, announced to screen readers.
class LoadingView extends StatelessWidget {
  final String? label;

  const LoadingView({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        label: label ?? 'Loading',
        liveRegion: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (label != null) ...[
              const SizedBox(height: 14),
              Text(label!, style: TextStyle(color: AppColors.muted)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Pulsing grey shape used by skeleton placeholders.
class _Pulse extends StatefulWidget {
  final Widget child;
  const _Pulse({required this.child});

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return widget.child;
    return FadeTransition(
      opacity: Tween(begin: 0.55, end: 1.0).animate(_c),
      child: widget.child,
    );
  }
}

class _Block extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  const _Block({this.width, required this.height, this.radius = 8});

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: AppColors.track,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

/// Placeholder shaped like an [ItemCard], shown while the feed loads.
class ItemCardSkeleton extends StatelessWidget {
  const ItemCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        color: AppColors.surface,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: _Pulse(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  _Block(width: 40, height: 40, radius: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Block(width: 120, height: 14),
                        SizedBox(height: 6),
                        _Block(width: 70, height: 11),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AspectRatio(
                aspectRatio: 4 / 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.track,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const _Block(width: 200, height: 18),
            ],
          ),
        ),
      ),
    );
  }
}

/// A short list of skeleton cards.
class FeedSkeleton extends StatelessWidget {
  final int count;
  const FeedSkeleton({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading items',
      liveRegion: true,
      child: Column(
        children: [for (var i = 0; i < count; i++) const ItemCardSkeleton()],
      ),
    );
  }
}

/// Slim banner shown when the device is offline.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        color: AppColors.snack,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: const Row(
          children: [
            Icon(Icons.wifi_off_rounded, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'You\'re offline. Changes will sync when you reconnect.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal step tracker for a multi-stage transaction
/// (e.g. Reported → Claim sent → Approved → Returned).
class ProgressSteps extends StatelessWidget {
  final List<String> steps;

  /// Index of the step currently in progress. Steps before it are done.
  final int current;

  /// Marks the current step as failed (shown in the error colour).
  final bool failed;

  const ProgressSteps({
    super.key,
    required this.steps,
    required this.current,
    this.failed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Step ${current + 1} of ${steps.length}: ${steps[current]}'
          '${failed ? ', failed' : ''}',
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < steps.length; i++) ...[
              Expanded(child: _step(i)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _step(int i) {
    final done = i < current;
    final active = i == current;
    final color = active && failed
        ? AppColors.error
        : (done || active)
        ? AppColors.primary
        : AppColors.track;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 2,
                color: i == 0
                    ? Colors.transparent
                    : (i <= current ? AppColors.primary : AppColors.track),
              ),
            ),
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: done || (active && failed) ? color : AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: done
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    )
                  : active && failed
                  ? const Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
            Expanded(
              child: Container(
                height: 2,
                color: i == steps.length - 1
                    ? Colors.transparent
                    : (i < current ? AppColors.primary : AppColors.track),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          steps[i],
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? AppColors.ink : AppColors.muted,
          ),
        ),
      ],
    );
  }
}
