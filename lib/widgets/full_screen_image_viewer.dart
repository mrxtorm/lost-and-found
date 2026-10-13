import 'package:flutter/material.dart';

class FullScreenImageViewer extends StatefulWidget {
  final ImageProvider image;
  final String heroTag;
  final String? caption;

  const FullScreenImageViewer({
    super.key,
    required this.image,
    required this.heroTag,
    this.caption,
  });

  static Future<void> show(
      BuildContext context, {
        required ImageProvider image,
        required String heroTag,
        String? caption,
      }) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (_, _, _) => FullScreenImageViewer(
          image: image,
          heroTag: heroTag,
          caption: caption,
        ),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer>
    with SingleTickerProviderStateMixin {
  final TransformationController _controller = TransformationController();
  late final AnimationController _zoomController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  Animation<Matrix4>? _zoomAnimation;
  Offset _doubleTapPosition = Offset.zero;

  // Swipe-down-to-close state (only while not zoomed in).
  int _pointers = 0;
  double _dragDy = 0;
  bool _dragging = false;

  bool get _isZoomed => _controller.value.getMaxScaleOnAxis() > 1.02;

  @override
  void initState() {
    super.initState();
    _zoomController.addListener(() {
      final animation = _zoomAnimation;
      if (animation != null) _controller.value = animation.value;
    });
  }

  @override
  void dispose() {
    _zoomController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _toggleZoom() {
    final Matrix4 target;
    if (_isZoomed) {
      target = Matrix4.identity();
    } else {
      const scale = 2.5;
      final p = _doubleTapPosition;
      // Zoom in around the tapped point.
      target = Matrix4.translationValues(
        -p.dx * (scale - 1),
        -p.dy * (scale - 1),
        0,
      ) *
          Matrix4.diagonal3Values(scale, scale, 1);
    }

    _zoomAnimation = Matrix4Tween(begin: _controller.value, end: target)
        .animate(
      CurvedAnimation(parent: _zoomController, curve: Curves.easeOutCubic),
    );
    _zoomController.forward(from: 0);
  }

  void _onPointerDown(PointerDownEvent event) {
    _pointers++;
    if (_pointers > 1) _resetDrag(); // second finger = pinch, not a swipe
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_pointers != 1 || _isZoomed) return;
    if (!_dragging && event.delta.dy.abs() <= event.delta.dx.abs()) return;
    setState(() {
      _dragging = true;
      _dragDy += event.delta.dy;
    });
  }

  void _onPointerUp(PointerEvent event) {
    if (_pointers > 0) _pointers--;
    if (_pointers > 0) return;

    if (_dragging && _dragDy.abs() > 110) {
      Navigator.of(context).maybePop();
      return;
    }
    _resetDrag();
  }

  void _resetDrag() {
    if (!_dragging && _dragDy == 0) return;
    setState(() {
      _dragging = false;
      _dragDy = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_dragDy.abs() / 300).clamp(0.0, 1.0).toDouble();
    final backgroundOpacity = 1.0 - (progress * 0.7);
    final chromeOpacity = _dragging ? 0.0 : 1.0;

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: backgroundOpacity),
      body: Stack(
        children: [
          Positioned.fill(
            child: Listener(
              onPointerDown: _onPointerDown,
              onPointerMove: _onPointerMove,
              onPointerUp: _onPointerUp,
              onPointerCancel: _onPointerUp,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onDoubleTapDown: (details) =>
                _doubleTapPosition = details.localPosition,
                onDoubleTap: _toggleZoom,
                child: AnimatedContainer(
                  duration: _dragging
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  transform: Matrix4.translationValues(0, _dragDy, 0),
                  child: InteractiveViewer(
                    transformationController: _controller,
                    minScale: 1,
                    maxScale: 5,
                    child: Center(
                      child: Hero(
                        tag: widget.heroTag,
                        child: Image(
                          image: widget.image,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white54,
                            size: 64,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Close button
          SafeArea(
            child: AnimatedOpacity(
              opacity: chromeOpacity,
              duration: const Duration(milliseconds: 120),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    color: Colors.white,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black45,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Caption
          if (widget.caption != null && widget.caption!.isNotEmpty)
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                child: AnimatedOpacity(
                  opacity: chromeOpacity,
                  duration: const Duration(milliseconds: 120),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                    child: Text(
                      widget.caption!,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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