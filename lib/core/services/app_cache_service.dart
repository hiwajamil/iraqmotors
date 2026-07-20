import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iq_motors/core/config/app_image_cache.dart';
import 'package:iq_motors/shared/presentation/providers/car_metadata_providers.dart';

/// Central facade for clearing app-owned caches (images + optional metadata).
class AppCacheService {
  AppCacheService({void Function()? onClearMetadata})
      : _onClearMetadata = onClearMetadata;

  final void Function()? _onClearMetadata;

  /// Clears the shared disk cache used by [CachedNetworkImage].
  Future<void> clearImageDiskCache() => AppImageCacheManager.emptyCache();

  /// Evicts Flutter's in-memory decoded image cache.
  void clearImageMemoryCache() {
    final cache = PaintingBinding.instance.imageCache;
    cache.clear();
    cache.clearLiveImages();
  }

  /// Clears disk + memory image caches, and optionally the car-metadata
  /// session cache via [onClearMetadata].
  Future<void> clearAll({bool includeMetadata = true}) async {
    clearImageMemoryCache();
    await clearImageDiskCache();
    if (includeMetadata) {
      _onClearMetadata?.call();
    }
  }
}

final appCacheServiceProvider = Provider<AppCacheService>((ref) {
  return AppCacheService(
    onClearMetadata: () {
      ref.read(carMetadataServiceProvider).clearCache();
    },
  );
});
