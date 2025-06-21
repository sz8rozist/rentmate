import 'package:flutter/material.dart';

/// Megjelenít egy swipe-olható, fullscreen képgalériát.
///
/// [context]: BuildContext
/// [children]: A képek listája, amik ImageProvider típusúak (pl. NetworkImage, FileImage)
/// [initialIndex]: Melyik képnél kezdjen a galéria (default: 0)
/// [swipeDismissible]: Ha true, lefelé húzva bezárható a galéria (default: false)
Future<void> showSwipeImageGallery(
    BuildContext context, {
      required List<ImageProvider> children,
      int initialIndex = 0,
      bool swipeDismissible = false,
    }) {
  return Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierDismissible: swipeDismissible,
      pageBuilder: (context, animation, secondaryAnimation) {
        return _SwipeImageGalleryPage(
          images: children,
          initialIndex: initialIndex,
          swipeDismissible: swipeDismissible,
        );
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    ),
  );
}

class _SwipeImageGalleryPage extends StatefulWidget {
  final List<ImageProvider> images;
  final int initialIndex;
  final bool swipeDismissible;

  const _SwipeImageGalleryPage({
    super.key,
    required this.images,
    required this.initialIndex,
    required this.swipeDismissible,
  });

  @override
  State<_SwipeImageGalleryPage> createState() => _SwipeImageGalleryPageState();
}

class _SwipeImageGalleryPageState extends State<_SwipeImageGalleryPage> {
  late final PageController _pageController;
  late int _currentIndex;
  double _verticalDrag = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (!widget.swipeDismissible) return;
    setState(() {
      _verticalDrag += details.delta.dy;
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (!widget.swipeDismissible) return;
    if (_verticalDrag > 150) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _verticalDrag = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final opacity = 1.0 - (_verticalDrag.abs() / 300).clamp(0, 1);

    return GestureDetector(
      onVerticalDragUpdate: _onVerticalDragUpdate,
      onVerticalDragEnd: _onVerticalDragEnd,
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: Colors.black.withOpacity(opacity),
        body: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  child: Center(
                    child: Image(
                      image: widget.images[index],
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Text(
                          'Kép betöltési hiba',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 40 + MediaQuery.of(context).padding.top,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            if (widget.images.length > 1)
              Positioned(
                bottom: 30 + MediaQuery.of(context).padding.bottom,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    '${_currentIndex + 1} / ${widget.images.length}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
