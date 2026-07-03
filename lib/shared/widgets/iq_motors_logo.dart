import 'package:flutter/material.dart';

import 'package:iq_motors/core/config/app_image_cache.dart';

/// IQ Motors brand logo for headers and marketing surfaces.
class IqMotorsLogo extends StatelessWidget {
  const IqMotorsLogo({
    super.key,
    this.height = 36,
    this.width,
    this.light = false,
    this.compact = false,
    this.onTap,
  });

  /// Logo height; width scales with the image aspect ratio when [width] is null.
  final double height;

  /// Optional width cap; use for wide wordmarks so height alone undersizes them.
  final double? width;

  /// `true` = white logo for dark / hero backgrounds.
  final bool light;

  /// Icon mark only (no wordmark) for narrow layouts.
  final bool compact;

  final VoidCallback? onTap;

  static const String assetPath = 'assets/images/IQ33.png';

  @override
  Widget build(BuildContext context) {
    final cacheWidth = networkImageMemCacheExtent(context, width ?? height * 2);
    final image = Image.asset(
      assetPath,
      height: height,
      width: width,
      fit: BoxFit.contain,
      cacheWidth: cacheWidth,
      semanticLabel: 'IQ Motors',
      filterQuality: FilterQuality.medium,
    );

    if (onTap == null) return image;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: image,
      ),
    );
  }
}
