import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:iq_motors/core/config/app_image_cache.dart';

import 'package:iq_motors/features/listings/domain/models/add_car_draft.dart';
import 'package:iq_motors/features/listings/presentation/add_car_theme.dart';

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
      final cacheExtent = networkImageMemCacheExtent(context, 400);
      return Image.network(
        path,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        cacheWidth: cacheExtent,
        cacheHeight: cacheExtent,
        gaplessPlayback: true,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _loadingPlaceholder(context, loadingProgress);
        },
        errorBuilder: (context, __, ___) => _errorPlaceholder(context),
      );
    }

    return Image.file(
      File(path),
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      gaplessPlayback: true,
      errorBuilder: (context, __, ___) => _errorPlaceholder(context),
    );
  }

  Widget _loadingPlaceholder(BuildContext context, ImageChunkEvent progress) {
    final total = progress.expectedTotalBytes;
    final loaded = progress.cumulativeBytesLoaded;
    final value = total != null ? loaded / total : null;

    return ColoredBox(
      color: AddCarTheme.inputFill(context),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            value: value,
            color: AddCarTheme.focus(context),
          ),
        ),
      ),
    );
  }

  Widget _errorPlaceholder(BuildContext context) {
    return ColoredBox(
      color: AddCarTheme.textPrimary(context).withValues(alpha: 0.06),
      child: Icon(
        Icons.directions_car_rounded,
        size: 36,
        color: AddCarTheme.textSecondary(context),
      ),
    );
  }
}
