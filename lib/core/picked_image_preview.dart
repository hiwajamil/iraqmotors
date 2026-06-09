import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/add_car_draft.dart';
import '../views/add_car/add_car_theme.dart';

/// Renders a preview for a locally picked or remote listing image.
///
/// On web, [image_picker] returns blob URLs — use [Image.network] instead of
/// [Image.file].
class PickedImagePreview extends StatelessWidget {
  const PickedImagePreview({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
  });

  final String path;
  final BoxFit fit;

  static bool useNetworkDecoder(String path) =>
      kIsWeb ||
      path.startsWith('blob:') ||
      AddCarDraft.isRemoteImageUrl(path);

  @override
  Widget build(BuildContext context) {
    if (useNetworkDecoder(path)) {
      return Image.network(
        path,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _errorPlaceholder(),
      );
    }

    return Image.file(
      File(path),
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => _errorPlaceholder(),
    );
  }

  Widget _errorPlaceholder() {
    return ColoredBox(
      color: AddCarTheme.textPrimary.withValues(alpha: 0.06),
      child: const Icon(
        Icons.directions_car_rounded,
        size: 36,
        color: AddCarTheme.textSecondary,
      ),
    );
  }
}
