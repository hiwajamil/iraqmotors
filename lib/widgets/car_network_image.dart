import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Network car photo that loads on Flutter web without R2 CORS headers.
///
/// CanvasKit treats cross-origin images as tainted unless the host sends CORS.
/// [WebHtmlElementStrategy.prefer] uses a plain HTML `<img>` on web instead.
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

    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: loadingBuilder,
      webHtmlElementStrategy: kIsWeb
          ? WebHtmlElementStrategy.prefer
          : WebHtmlElementStrategy.never,
      errorBuilder: errorBuilder,
    );
  }
}
