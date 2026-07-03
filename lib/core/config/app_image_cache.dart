import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Shared disk cache for [CachedNetworkImage] with a bounded object count.
class AppImageCacheManager {
  AppImageCacheManager._();

  static const _cacheKey = 'iqMotorsImageCache';

  static final CacheManager instance = CacheManager(
    Config(
      _cacheKey,
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 60,
    ),
  );
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
