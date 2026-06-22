import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'car_network_image_stub.dart'
    if (dart.library.html) 'car_network_image_web.dart' as platform;

/// Network car photo that loads on Flutter web without R2 CORS headers.
///
/// On web, renders a plain HTML `<img>` with CSS `object-fit` so photos keep
/// their aspect ratio inside card and detail layouts.
class CarNetworkImage extends StatelessWidget {
  const CarNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.loadingBuilder,
    this.errorBuilder,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final ImageLoadingBuilder? loadingBuilder;
  final ImageErrorWidgetBuilder? errorBuilder;

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

    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: loadingBuilder,
      errorBuilder: errorBuilder,
    );
  }
}
