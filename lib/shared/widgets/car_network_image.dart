import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:iq_motors/core/config/app_image_cache.dart';

/// Network car photo with memory-cache sizing on all platforms.
///
/// On web, uses [Image.network] with [WebHtmlElementStrategy.fallback]: resized
/// decode when CORS allows, otherwise a native HTML `<img>` (no CORS required).
/// On mobile/desktop, uses [CachedNetworkImage].
class CarNetworkImage extends StatelessWidget {
  const CarNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.loadingBuilder,
    this.errorBuilder,
    /// Target logical width for memory-cache sizing when [width] is null.
    this.cacheLogicalWidth = 200,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final ImageLoadingBuilder? loadingBuilder;
  final ImageErrorWidgetBuilder? errorBuilder;
  final double cacheLogicalWidth;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl.trim();
    if (url.isEmpty) {
      return errorBuilder?.call(context, Object(), StackTrace.current) ??
          const SizedBox.shrink();
    }

    final cacheWidth = networkImageMemCacheExtent(
      context,
      width ?? cacheLogicalWidth,
    );
    final cacheHeight = networkImageMemCacheHeight(context, height);

    if (kIsWeb) {
      return Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: cacheWidth,
        cacheHeight: cacheHeight,
        webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
        loadingBuilder: loadingBuilder,
        errorBuilder: errorBuilder,
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: cacheWidth,
      memCacheHeight: cacheHeight,
      maxWidthDiskCache: cacheWidth,
      maxHeightDiskCache: cacheHeight,
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
        return const ColoredBox(color: Color(0xFFF5F5F7));
      },
      errorWidget: (context, error, stackTrace) {
        return errorBuilder?.call(
              context,
              error,
              stackTrace is StackTrace ? stackTrace : StackTrace.current,
            ) ??
            const ColoredBox(color: Color(0xFFF5F5F7));
      },
    );
  }
}
