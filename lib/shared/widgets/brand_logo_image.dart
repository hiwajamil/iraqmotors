import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:iq_motors/core/config/app_image_cache.dart';
import 'package:iq_motors/shared/models/car_brand.dart';

/// Renders a high-fidelity vector SVG brand logo with automated raster PNG fallback.
class BrandLogoImage extends StatefulWidget {
  const BrandLogoImage({
    super.key,
    required this.brand,
    this.size = 48,
    this.fit = BoxFit.contain,
    this.color,
  });

  final CarBrand brand;
  final double size;
  final BoxFit fit;
  final Color? color;

  @override
  State<BrandLogoImage> createState() => _BrandLogoImageState();
}

class _BrandLogoImageState extends State<BrandLogoImage> {
  int _attemptIndex = 0;

  List<String> get _sourceUrls {
    final slug = _slugify(widget.brand.id);
    return [
      'https://cdn.jsdelivr.net/gh/filippofilip95/car-logos-dataset@master/logos/vector/$slug.svg',
      'https://cdn.jsdelivr.net/npm/simple-icons@v13/icons/$slug.svg',
      widget.brand.logoUrl,
    ];
  }

  static String _slugify(String input) {
    return input.replaceAll('_', '-').replaceAll(' ', '-').toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    if (_attemptIndex >= _sourceUrls.length) {
      return _buildLetterFallback(context);
    }

    final currentUrl = _sourceUrls[_attemptIndex];
    final isSvg = currentUrl.endsWith('.svg');

    if (isSvg) {
      return SvgPicture.network(
        currentUrl,
        width: widget.size,
        height: widget.size,
        fit: widget.fit,
        colorFilter: widget.color != null
            ? ColorFilter.mode(widget.color!, BlendMode.srcIn)
            : null,
        placeholderBuilder: (context) => _buildPlaceholder(),
        errorBuilder: (context, error, stackTrace) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _attemptIndex < _sourceUrls.length) {
              setState(() => _attemptIndex++);
            }
          });
          return _buildPlaceholder();
        },
      );
    }

    final cacheExtent =
        (widget.size * MediaQuery.devicePixelRatioOf(context)).round();

    return CachedNetworkImage(
      imageUrl: currentUrl,
      width: widget.size,
      height: widget.size,
      fit: widget.fit,
      memCacheWidth: cacheExtent,
      memCacheHeight: cacheExtent,
      maxWidthDiskCache: cacheExtent,
      maxHeightDiskCache: cacheExtent,
      cacheManager: AppImageCacheManager.instance,
      placeholder: (_, __) => _buildPlaceholder(),
      errorWidget: (context, error, stackTrace) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _attemptIndex < _sourceUrls.length) {
            setState(() => _attemptIndex++);
          }
        });
        return _buildLetterFallback(context);
      },
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: SizedBox(
        width: widget.size * 0.3,
        height: widget.size * 0.3,
        child: const CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildLetterFallback(BuildContext context) {
    final letter = widget.brand.nameEnglish.isNotEmpty
        ? widget.brand.nameEnglish[0].toUpperCase()
        : 'C';
    return Center(
      child: Text(
        letter,
        style: TextStyle(
          fontSize: widget.size * 0.38,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
