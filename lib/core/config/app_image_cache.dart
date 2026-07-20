import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Shared disk cache for [CachedNetworkImage] with a bounded object count.
///
/// Sized for marketplace scroll density: enough listing thumbs/hero frames for
/// a typical session without unbounded device storage growth.
class AppImageCacheManager {
  AppImageCacheManager._();

  static const _cacheKey = 'iqMotorsImageCache';

  /// How long disk entries remain valid before revalidation.
  static const Duration stalePeriod = Duration(days: 7);

  /// Max files retained on disk by the cache manager.
  static const int maxNrOfCacheObjects = 300;

  /// Max decoded images held in Flutter's in-memory [ImageCache].
  static const int paintingCacheMaximumSize = 250;

  /// Max bytes for Flutter's in-memory [ImageCache] (100 MB).
  static const int paintingCacheMaximumSizeBytes = 100 * 1024 * 1024;

  static final CacheManager instance = CacheManager(
    Config(
      _cacheKey,
      stalePeriod: stalePeriod,
      maxNrOfCacheObjects: maxNrOfCacheObjects,
    ),
  );

  /// Clears all files from the shared disk image cache.
  static Future<void> emptyCache() => instance.emptyCache();

  /// Applies bounded [ImageCache] limits. Call once after
  /// [WidgetsFlutterBinding.ensureInitialized].
  static void configurePaintingCache() {
    final cache = PaintingBinding.instance.imageCache;
    cache.maximumSize = paintingCacheMaximumSize;
    cache.maximumSizeBytes = paintingCacheMaximumSizeBytes;
  }
}

/// Target pixel width/height for in-memory image decode (`memCacheWidth`, `cacheWidth`).
int networkImageMemCacheExtent(
  BuildContext context,
  double logicalSize, {
  int max = 800,
}) {
  final dpr = MediaQuery.devicePixelRatioOf(context);
  return (logicalSize * dpr).round().clamp(1, max);
}

/// Optional height extent when a fixed logical height is known.
int? networkImageMemCacheHeight(
  BuildContext context,
  double? logicalHeight, {
  int max = 800,
}) {
  if (logicalHeight == null) return null;
  return networkImageMemCacheExtent(context, logicalHeight, max: max);
}
