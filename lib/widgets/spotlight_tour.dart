import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// One highlighted element in a [showSpotlightTour].
class SpotlightStep {
  /// Key of the widget to highlight.
  final GlobalKey targetKey;

  /// Optional: narrows the highlight to part of the target (for example one
  /// destination of a NavigationBar). Receives the target's global rect.
  final Rect Function(Rect targetRect)? rectOf;

  final IconData icon;
  final String title;
  final String description;

  /// Corner radius of the cut-out.
  final double radius;

  const SpotlightStep({
    required this.targetKey,
    required this.icon,
    required this.title,
    required this.description,
    this.rectOf,
    this.radius = 16,
  });
}

/// Darkens the screen, cuts a hole around each step's target and shows a
/// description card next to it. The user taps Next (or anywhere on the dim
/// background) to continue, or Skip to end the tour early.
///
/// Steps whose target is not on screen are skipped.
Future<void> showSpotlightTour(
  BuildContext context,
  List<SpotlightStep> steps,
) async {
  final overlay = Overlay.of(context, rootOverlay: true);
  final done = Completer<void>();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _SpotlightOverlay(
      steps: steps,
      onFinish: () {
        if (done.isCompleted) return;
        entry.remove();
        done.complete();
      },
    ),
  );
  overlay.insert(entry);
  await done.future;
}

class _SpotlightOverlay extends StatefulWidget {
  final List<SpotlightStep> steps;
  final VoidCallback onFinish;

  const _SpotlightOverlay({required this.steps, required this.onFinish});

  @override
  State<_SpotlightOverlay> createState() => _SpotlightOverlayState();
}

class _SpotlightOverlayState extends State<_SpotlightOverlay>
    with SingleTickerProviderStateMixin {
  static const _padding = 8.0;

  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );

  int _index = -1;
  Rect? _from;
  Rect? _to;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _goTo(0));
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  /// Global rect of [step]'s target, or null if it is not laid out.
  Rect? _measure(SpotlightStep step) {
    final ctx = step.targetKey.currentContext;
    final box = ctx?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached || !box.hasSize) return null;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    return (step.rectOf?.call(rect) ?? rect).inflate(_padding);
  }

  Future<void> _goTo(int index) async {
    if (_busy) return;
    _busy = true;
    try {
      var i = index;
      while (i < widget.steps.length) {
        final ctx = widget.steps[i].targetKey.currentContext;
        if (ctx != null && ctx.mounted && Scrollable.maybeOf(ctx) != null) {
          // Bring targets inside scroll views (e.g. the search bar) into view.
          await Scrollable.ensureVisible(
            ctx,
            alignment: 0.3,
            duration: const Duration(milliseconds: 250),
          );
        }
        if (!mounted) return;
        final rect = _measure(widget.steps[i]);
        if (rect != null) {
          HapticFeedback.selectionClick();
          setState(() {
            _from = _currentRect ?? rect;
            _to = rect;
            _index = i;
          });
          _anim.forward(from: 0);
          return;
        }
        i++;
      }
      widget.onFinish();
    } finally {
      _busy = false;
    }
  }

  Rect? get _currentRect {
    if (_from == null || _to == null) return null;
    return Rect.lerp(_from, _to, Curves.easeInOutCubic.transform(_anim.value));
  }

  void _next() => _goTo(_index + 1);

  void _back() {
    if (_index > 0) _goTo(_index - 1);
  }

  @override
  Widget build(BuildContext context) {
    if (_index < 0) return const SizedBox.shrink();
    final step = widget.steps[_index];
    final isLast = _index == widget.steps.length - 1;

    return Material(
      type: MaterialType.transparency,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) {
          final rect = _currentRect!;
          final size = MediaQuery.sizeOf(context);
          final padding = MediaQuery.paddingOf(context);
          // Card goes on whichever side of the highlight has more room.
          final below = rect.center.dy < size.height / 2;

          return Stack(
            children: [
              // Dim background; tapping it advances the tour. It also
              // swallows taps so the app underneath can't be used.
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _next,
                  child: CustomPaint(
                    painter: _SpotlightPainter(
                      hole: rect,
                      radius: step.radius,
                      glow: _anim.value,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                top: below ? rect.bottom + 14 : null,
                bottom: below ? null : size.height - rect.top + 14,
                child: FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _anim,
                    curve: const Interval(0.4, 1, curve: Curves.easeOut),
                  ),
                  child: _TourCard(
                    step: step,
                    index: _index,
                    total: widget.steps.length,
                    isLast: isLast,
                    onNext: _next,
                    onBack: _index > 0 ? _back : null,
                  ),
                ),
              ),
              Positioned(
                top: padding.top + 8,
                right: 12,
                child: AnimatedOpacity(
                  opacity: isLast ? 0 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      shape: const StadiumBorder(),
                    ),
                    onPressed: isLast ? null : widget.onFinish,
                    child: const Text('Skip tour'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TourCard extends StatelessWidget {
  final SpotlightStep step;
  final int index;
  final int total;
  final bool isLast;
  final VoidCallback onNext;
  final VoidCallback? onBack;

  const _TourCard({
    required this.step,
    required this.index,
    required this.total,
    required this.isLast,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd + 4),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(step.icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  step.title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            step.description,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.45,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '${index + 1} of $total',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
              const Spacer(),
              if (onBack != null)
                TextButton(onPressed: onBack, child: const Text('Back')),
              const SizedBox(width: 4),
              FilledButton(
                onPressed: onNext,
                child: Text(isLast ? 'Got it!' : 'Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Rect hole;
  final double radius;
  final double glow;

  _SpotlightPainter({
    required this.hole,
    required this.radius,
    required this.glow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(hole, Radius.circular(radius));
    final dim = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(rrect);
    canvas.drawPath(dim, Paint()..color = Colors.black.withValues(alpha: 0.72));

    // Soft ring that grows in once the highlight settles.
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = Colors.white.withValues(alpha: 0.9 * glow);
    canvas.drawRRect(rrect, ring);
    canvas.drawRRect(
      rrect.inflate(6 * glow),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = AppColors.primary.withValues(alpha: 0.35 * (1 - glow * 0.5))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.hole != hole || old.radius != radius || old.glow != glow;
}
