import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Short confetti burst + "Item returned" badge shown on top of the current
/// screen. Ignores touches and removes itself, so the app stays usable.
class CelebrationOverlay {
  CelebrationOverlay._();

  static void show(OverlayState? overlay) {
    if (overlay == null) return;

    HapticFeedback.mediumImpact();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _CelebrationView(onDone: () => entry.remove()),
    );
    overlay.insert(entry);
  }
}

class _CelebrationView extends StatefulWidget {
  final VoidCallback onDone;
  const _CelebrationView({required this.onDone});

  @override
  State<_CelebrationView> createState() => _CelebrationViewState();
}

class _CelebrationViewState extends State<_CelebrationView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final random = math.Random();
    const colors = [
      AppColors.primary,
      AppColors.found,
      AppColors.warn,
      AppColors.lost,
      Color(0xFFB54CF0),
    ];
    _particles = List.generate(70, (_) {
      return _Particle(
        angle: -math.pi / 2 + (random.nextDouble() - 0.5) * math.pi * 0.9,
        speed: 280 + random.nextDouble() * 420,
        size: 5 + random.nextDouble() * 6,
        spin: (random.nextDouble() - 0.5) * 12,
        color: colors[random.nextInt(colors.length)],
      );
    });
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          // Badge pops in, holds, then fades.
          final pop = Curves.elasticOut.transform((t / 0.3).clamp(0.0, 1.0));
          final fade = t < 0.75 ? 1.0 : (1 - (t - 0.75) / 0.25);
          return Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(painter: _ConfettiPainter(_particles, t)),
              Align(
                alignment: const Alignment(0, -0.2),
                child: Opacity(
                  opacity: fade.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: pop,
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.found,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle,
                                color: Colors.white, size: 28),
                            SizedBox(width: 10),
                            Text(
                              'Item returned!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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

class _Particle {
  final double angle, speed, size, spin;
  final Color color;
  const _Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.spin,
    required this.color,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double t;
  _ConfettiPainter(this.particles, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height * 0.55);
    final seconds = t * 2.6;
    const gravity = 900.0;
    final paint = Paint();

    for (final p in particles) {
      final x = origin.dx + math.cos(p.angle) * p.speed * seconds;
      final y = origin.dy +
          math.sin(p.angle) * p.speed * seconds +
          0.5 * gravity * seconds * seconds;
      paint.color = p.color.withValues(alpha: (1 - t).clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * seconds);
      canvas.drawRect(
        Rect.fromCenter(
            center: Offset.zero, width: p.size, height: p.size * 0.6),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
