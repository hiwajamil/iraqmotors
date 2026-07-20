import 'dart:async';
import 'package:flutter/material.dart';
import 'package:iq_motors/shared/widgets/car_network_image.dart';

/// Full-width swipeable image gallery carousel with page indicators.
class ImageGalleryCarousel extends StatefulWidget {
  const ImageGalleryCarousel({
    super.key,
    required this.images,
  });

  final List<String> images;

  @override
  State<ImageGalleryCarousel> createState() => _ImageGalleryCarouselState();
}

class _ImageGalleryCarouselState extends State<ImageGalleryCarousel> {
  static const double _radius = 16;
  static const Duration _autoPlayInterval = Duration(seconds: 4);
  static const Duration _pageAnimationDuration = Duration(milliseconds: 300);

  late final PageController _pageController;
  Timer? _autoPlayTimer;
  int _currentPage = 0;

  List<String> get _images => widget.images;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoPlay();
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    if (_images.length <= 1) return;
    _autoPlayTimer = Timer.periodic(_autoPlayInterval, (_) => _goToNext());
  }

  void _goToNext() {
    if (!mounted || !_pageController.hasClients || _images.length <= 1) return;
    final next = (_currentPage + 1) % _images.length;
    _pageController.animateToPage(
      next,
      duration: _pageAnimationDuration,
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_images.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: AspectRatio(
          aspectRatio: 16 / 10,
          child: Container(
            color: colorScheme.surfaceContainerHighest,
            alignment: Alignment.center,
            child: Icon(
              Icons.directions_car_outlined,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(_radius),
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _images.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) {
                return CarNetworkImage(
                  imageUrl: _images[index],
                  fit: BoxFit.cover,
                );
              },
            ),
          ),
        ),
        if (_images.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _images.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _currentPage == i ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: _currentPage == i
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
