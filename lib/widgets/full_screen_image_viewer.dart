import 'package:flutter/material.dart';

class FullScreenImageViewer extends StatefulWidget {
  final List<ImageProvider> images;
  final int initialIndex;
  final String heroTag;
  final String? caption;

  const FullScreenImageViewer({
    super.key,
    required this.images,
    this.initialIndex = 0,
    required this.heroTag,
    this.caption,
  });

  /// Pass a single [image], or [images] (with [initialIndex]) to let the user
  /// swipe between photos.
  static Future<void> show(
    BuildContext context, {
    ImageProvider? image,
    List<ImageProvider>? images,
    int initialIndex = 0,
    required String heroTag,
    String? caption,
  }) {
    final list = images ?? [if (image != null) image];
    if (list.isEmpty) return Future.value();
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (_, _, _) => FullScreenImageViewer(
          images: list,
          initialIndex: initialIndex.clamp(0, list.length - 1),
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

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late final PageController _pageController =
      PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  // Swipe-down-to-close state (only while not zoomed in).
  int _pointers = 0;
  double _dragDy = 0;
  bool _dragging = false;
  bool _zoomed = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    _pointers++;
    if (_pointers > 1) _resetDrag(); // second finger = pinch, not a swipe
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_pointers != 1 || _zoomed) return;
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
    final count = widget.images.length;
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
              child: AnimatedContainer(
                duration: _dragging
                    ? Duration.zero
                    : const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                transform: Matrix4.translationValues(0, _dragDy, 0),
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: count,
                  // While zoomed, one-finger drags pan the photo instead.
                  physics: _zoomed
                      ? const NeverScrollableScrollPhysics()
                      : const PageScrollPhysics(),
                  onPageChanged: (i) => setState(() {
                    _index = i;
                    _zoomed = false;
                  }),
                  itemBuilder: (context, i) => _ZoomablePhoto(
                    image: widget.images[i],
                    heroTag: i == widget.initialIndex ? widget.heroTag : null,
                    onZoomChanged: (zoomed) {
                      if (zoomed != _zoomed) setState(() => _zoomed = zoomed);
                    },
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
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      color: Colors.white,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black45,
                      ),
                    ),
                    const Spacer(),
                    if (count > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${_index + 1}/$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
          ),

          // Caption + dots
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: AnimatedOpacity(
                opacity: chromeOpacity,
                duration: const Duration(milliseconds: 120),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (count > 1)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (var i = 0; i < count; i++)
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  width: i == _index ? 8 : 6,
                                  height: i == _index ? 8 : 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: i == _index
                                        ? Colors.white
                                        : Colors.white38,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      if (widget.caption != null && widget.caption!.isNotEmpty)
                        Text(
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
                    ],
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

/// One zoomable page: pinch, pan and double-tap zoom.
class _ZoomablePhoto extends StatefulWidget {
  final ImageProvider image;
  final String? heroTag;
  final ValueChanged<bool> onZoomChanged;

  const _ZoomablePhoto({
    required this.image,
    required this.heroTag,
    required this.onZoomChanged,
  });

  @override
  State<_ZoomablePhoto> createState() => _ZoomablePhotoState();
}

class _ZoomablePhotoState extends State<_ZoomablePhoto>
    with SingleTickerProviderStateMixin {
  final TransformationController _controller = TransformationController();
  late final AnimationController _zoomController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  Animation<Matrix4>? _zoomAnimation;
  Offset _doubleTapPosition = Offset.zero;

  bool get _isZoomed => _controller.value.getMaxScaleOnAxis() > 1.02;

  @override
  void initState() {
    super.initState();
    _zoomController.addListener(() {
      final animation = _zoomAnimation;
      if (animation != null) _controller.value = animation.value;
    });
    _controller.addListener(() => widget.onZoomChanged(_isZoomed));
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

  @override
  Widget build(BuildContext context) {
    Widget photo = Image(
      image: widget.image,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const Icon(
        Icons.broken_image_outlined,
        color: Colors.white54,
        size: 64,
      ),
    );
    if (widget.heroTag != null) {
      photo = Hero(tag: widget.heroTag!, child: photo);
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTapDown: (details) => _doubleTapPosition = details.localPosition,
      onDoubleTap: _toggleZoom,
      child: InteractiveViewer(
        transformationController: _controller,
        minScale: 1,
        maxScale: 5,
        child: Center(child: photo),
      ),
    );
  }
}
