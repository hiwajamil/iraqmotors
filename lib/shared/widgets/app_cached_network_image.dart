import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:iq_motors/core/config/app_image_cache.dart';

/// [CachedNetworkImage] with bounded memory/disk cache sizing by default.
class AppCachedNetworkImage extends StatelessWidget {
  const AppCachedNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.memCacheLogicalWidth,
    this.memCacheLogicalHeight,
    this.memCacheWidth,
    this.memCacheHeight,
    this.placeholder,
    this.errorWidget,
    this.filterQuality = FilterQuality.low,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final double? memCacheLogicalWidth;
  final double? memCacheLogicalHeight;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, Object)? errorWidget;
  final FilterQuality filterQuality;

  @override
  Widget build(BuildContext context) {
    final resolvedMemWidth = memCacheWidth ??
        (memCacheLogicalWidth != null
            ? networkImageMemCacheExtent(context, memCacheLogicalWidth!)
            : (width != null
                ? networkImageMemCacheExtent(context, width!)
                : null));
    final resolvedMemHeight = memCacheHeight ??
        networkImageMemCacheHeight(
          context,
          memCacheLogicalHeight ?? height,
        );

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: resolvedMemWidth,
      memCacheHeight: resolvedMemHeight,
      maxWidthDiskCache: resolvedMemWidth,
      maxHeightDiskCache: resolvedMemHeight,
      cacheManager: AppImageCacheManager.instance,
      filterQuality: filterQuality,
      placeholder: placeholder,
      errorWidget: errorWidget,
    );
  }
}
