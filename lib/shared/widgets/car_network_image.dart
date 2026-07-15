import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:iq_motors/core/config/app_image_cache.dart';

/// Network car photo with memory-cache sizing on all platforms.
///
/// On web, uses [Image.network] with [WebHtmlElementStrategy.fallback]: resized
/// decode when CORS allows, otherwise a native HTML `<img>` (no CORS required).
/// On mobile/desktop, uses [CachedNetworkImage].
///
/// Memory decode is constrained by width only so the bitmap keeps its native
/// aspect ratio; [BoxFit.cover] then crops inside the caller's clipped bounds.
class CarNetworkImage extends StatelessWidget {
  const CarNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.loadingBuilder,
    this.errorBuilder,
    /// Target logical width for memory-cache sizing when [width] is null.
    this.cacheLogicalWidth = 200,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final ImageLoadingBuilder? loadingBuilder;
  final ImageErrorWidgetBuilder? errorBuilder;
  final double cacheLogicalWidth;

  static const Color _placeholderColor = Color(0xFFF5F5F7);

  double? _resolveExtent(double? value, double constraintMax) {
    if (value != null && value.isFinite && value > 0) return value;
    if (constraintMax.isFinite && constraintMax > 0) return constraintMax;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final url = imageUrl.trim();
    if (url.isEmpty) {
      return errorBuilder?.call(context, Object(), StackTrace.current) ??
          const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final resolvedWidth = _resolveExtent(width, constraints.maxWidth);
        final resolvedHeight = _resolveExtent(height, constraints.maxHeight);

        final cacheWidth = networkImageMemCacheExtent(
          context,
          resolvedWidth ?? cacheLogicalWidth,
        );

        final Widget image;
        if (kIsWeb) {
          image = Image.network(
            url,
            width: resolvedWidth,
            height: resolvedHeight,
            fit: fit,
            alignment: alignment,
            cacheWidth: cacheWidth,
            webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
            loadingBuilder: loadingBuilder,
            errorBuilder: errorBuilder,
          );
        } else {
          image = CachedNetworkImage(
            imageUrl: url,
            width: resolvedWidth,
            height: resolvedHeight,
            fit: fit,
            alignment: alignment,
            memCacheWidth: cacheWidth,
            maxWidthDiskCache: cacheWidth,
            cacheManager: AppImageCacheManager.instance,
            fadeInDuration: const Duration(milliseconds: 120),
            placeholder: (context, _) {
              if (loadingBuilder != null) {
                return loadingBuilder!(
                  context,
                  const SizedBox.shrink(),
                  null,
                );
              }
              return const ColoredBox(color: _placeholderColor);
            },
            errorWidget: (context, error, stackTrace) {
              return errorBuilder?.call(
                    context,
                    error,
                    stackTrace is StackTrace ? stackTrace : StackTrace.current,
                  ) ??
                  const ColoredBox(color: _placeholderColor);
            },
          );
        }

        if (resolvedWidth != null && resolvedHeight != null) {
          return ColoredBox(
            color: _placeholderColor,
            child: SizedBox(
              width: resolvedWidth,
              height: resolvedHeight,
              child: image,
            ),
          );
        }

        return ColoredBox(color: _placeholderColor, child: image);
      },
    );
  }
}
