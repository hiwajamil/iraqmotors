import 'package:flutter/material.dart';

/// IQ Motors brand logo for headers and marketing surfaces.
class IqMotorsLogo extends StatelessWidget {
  const IqMotorsLogo({
    super.key,
    this.height = 36,
    this.light = false,
    this.compact = false,
    this.onTap,
  });

  /// Logo height; width scales with the image aspect ratio.
  final double height;

  /// `true` = white logo for dark / hero backgrounds.
  final bool light;

  /// Icon mark only (no wordmark) for narrow layouts.
  final bool compact;

  final VoidCallback? onTap;

  String get _assetPath {
    if (compact) return 'assets/images/logo_iq_motors_mark.png';
    return light
        ? 'assets/images/logo_iq_motors_light.png'
        : 'assets/images/logo_iq_motors_dark.png';
  }

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      _assetPath,
      height: height,
      fit: BoxFit.contain,
      semanticLabel: 'IQ Motors',
      filterQuality: FilterQuality.high,
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
