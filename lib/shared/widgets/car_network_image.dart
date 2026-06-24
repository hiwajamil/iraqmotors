import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:iq_motors/shared/widgets/car_network_image_stub.dart'
    if (dart.library.html) 'package:iq_motors/shared/widgets/car_network_image_web.dart' as platform;

/// Network car photo that loads on Flutter web without R2 CORS headers.
///
/// On web, renders a plain HTML `<img>` with CSS `object-fit` so photos keep
/// their aspect ratio inside card and detail layouts.
/// On mobile/desktop, uses [CachedNetworkImage] with memory-cache sizing.
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

    if (kIsWeb) {
      return platform.buildWebCarNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: errorBuilder,
      );
    }

    final dpr = MediaQuery.devicePixelRatioOf(context);
    final memCacheWidth =
        ((width ?? cacheLogicalWidth) * dpr).round().clamp(1, 1200);
    final memCacheHeight =
        height != null ? (height! * dpr).round().clamp(1, 1200) : null;

    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
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
