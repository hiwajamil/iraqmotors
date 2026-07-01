import 'dart:ui';

/// A vehicle detection drawn on the camera preview.
class CarBoundingBox {
  const CarBoundingBox({
    required this.rect,
    required this.confidence,
    this.label,
    this.trackingId,
  });

  /// Normalized coordinates (0–1) relative to the camera image.
  final Rect rect;
  final double confidence;
  final String? label;
  final int? trackingId;
}

/// Gemini + catalog mapping after a high-confidence vehicle detection.
class CarIdentificationResult {
  const CarIdentificationResult({
    required this.brandId,
    this.modelKey,
    this.year,
    this.brandLabel,
    this.modelLabel,
    this.confidence,
  });

  final String brandId;
  final String? modelKey;
  final String? year;
  final String? brandLabel;
  final String? modelLabel;
  final double? confidence;

  bool get hasModel => modelKey != null && modelKey!.isNotEmpty;
}
