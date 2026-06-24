import 'package:flutter/material.dart';

/// Non-web stub; [CarNetworkImage] uses [Image.network] directly on IO platforms.
Widget buildWebCarNetworkImage({
  required String imageUrl,
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  ImageErrorWidgetBuilder? errorBuilder,
}) {
  return Image.network(
    imageUrl,
    width: width,
    height: height,
    fit: fit,
    errorBuilder: errorBuilder,
  );
}
