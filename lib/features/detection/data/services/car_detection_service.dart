import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

import 'package:iq_motors/features/detection/domain/models/car_bounding_box.dart';
import 'package:iq_motors/features/listings/data/services/car_vision_service.dart';
import 'package:iq_motors/features/marketplace/data/services/car_database_service.dart';
import 'package:iq_motors/features/marketplace/domain/models/car.dart';
import 'package:iq_motors/shared/data/car_models_by_brand.dart';
import 'package:iq_motors/shared/data/dummy_brands.dart';

/// Real-time vehicle detection + optional Gemini identification + Firestore lookup.
class CarDetectionService {
  CarDetectionService({
    CarVisionService? visionService,
    CarDatabaseService? databaseService,
    ObjectDetector? objectDetector,
    String? customModelAssetPath,
  })  : _vision = visionService ?? CarVisionService(),
        _database = databaseService ?? CarDatabaseService(),
        _customModelAssetPath = customModelAssetPath,
        _objectDetectorOverride = objectDetector;

  final CarVisionService _vision;
  final CarDatabaseService _database;
  final String? _customModelAssetPath;
  final ObjectDetector? _objectDetectorOverride;

  ObjectDetector? _streamDetector;
  DateTime? _lastIdentificationAt;
  String? _lastLookupKey;

  static const double confidenceThreshold = 0.85;
  static const Duration identificationCooldown = Duration(seconds: 3);

  static const _vehicleLabelHints = {
    'vehicle',
    'car',
    'automobile',
    'land vehicle',
    'motor vehicle',
    'truck',
    'suv',
    'van',
  };

  bool get isAvailable =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  ObjectDetector get _detector {
    final override = _objectDetectorOverride;
    if (override != null) return override;

    return _streamDetector ??= _customModelAssetPath != null
        ? ObjectDetector(
            options: LocalObjectDetectorOptions(
              mode: DetectionMode.stream,
              modelPath: _customModelAssetPath,
              classifyObjects: true,
              multipleObjects: true,
            ),
          )
        : ObjectDetector(
            options: ObjectDetectorOptions(
              mode: DetectionMode.stream,
              classifyObjects: true,
              multipleObjects: true,
            ),
          );
  }

  /// Processes one camera frame and returns bounding boxes for vehicles.
  Future<List<CarBoundingBox>> detectVehicles(InputImage inputImage) async {
    if (!isAvailable) return const [];

    try {
      final objects = await _detector.processImage(inputImage);
      final imageSize = inputImage.metadata?.size;
      if (imageSize == null || imageSize.width <= 0 || imageSize.height <= 0) {
        return const [];
      }

      final boxes = <CarBoundingBox>[];
      for (final object in objects) {
        final confidence = _bestLabelConfidence(object);
        if (!_looksLikeVehicle(object) && confidence < 0.5) continue;

        final box = object.boundingBox;
        boxes.add(
          CarBoundingBox(
            rect: Rect.fromLTRB(
              box.left / imageSize.width,
              box.top / imageSize.height,
              box.right / imageSize.width,
              box.bottom / imageSize.height,
            ),
            confidence: confidence,
            label: object.labels.isNotEmpty ? object.labels.first.text : null,
            trackingId: object.trackingId,
          ),
        );
      }

      boxes.sort((a, b) => b.confidence.compareTo(a.confidence));
      return boxes;
    } catch (e, stackTrace) {
      debugPrint('Car detection frame error: $e');
      debugPrint('$stackTrace');
      return const [];
    }
  }

  /// When [detection] meets [confidenceThreshold], identify make/model and search Firestore.
  Future<CarDetectionLookupResult?> lookupIfConfident({
    required CarBoundingBox detection,
    required File imageFile,
  }) async {
    if (detection.confidence < confidenceThreshold) return null;

    final now = DateTime.now();
    if (_lastIdentificationAt != null &&
        now.difference(_lastIdentificationAt!) < identificationCooldown) {
      return null;
    }

    _lastIdentificationAt = now;

    final analysis = await _vision.analyzeCarImage(imageFile);
    final suggestion = _vision.mapAnalysisToFormKeys(analysis);
    if (suggestion.brandId == null) return null;

    final lookupKey =
        '${suggestion.brandId}|${suggestion.modelKey ?? ''}|${analysis['year'] ?? ''}';
    if (_lastLookupKey == lookupKey) return null;
    _lastLookupKey = lookupKey;

    final brand = dummyBrands.firstWhere(
      (b) => b.id == suggestion.brandId,
      orElse: () => dummyBrands.first,
    );
    final modelLabel = suggestion.modelKey != null
        ? CarModelsByBrand.labelForModel(brand, suggestion.modelKey!, 'en')
        : null;

    final identification = CarIdentificationResult(
      brandId: suggestion.brandId!,
      modelKey: suggestion.modelKey,
      year: _nullableYear(analysis['year']),
      brandLabel: brand.displayName('en'),
      modelLabel: modelLabel,
      confidence: detection.confidence,
    );

    final listings = await _database.findListingsByDetection(
      brandId: identification.brandId,
      modelKey: identification.modelKey,
      year: identification.year,
    );

    return CarDetectionLookupResult(
      identification: identification,
      listings: listings,
    );
  }

  Future<void> dispose() async {
    if (_objectDetectorOverride == null) {
      await _streamDetector?.close();
    }
    await _vision.dispose();
  }

  double _bestLabelConfidence(DetectedObject object) {
    if (object.labels.isEmpty) {
      final area = object.boundingBox.width * object.boundingBox.height;
      return area > 0 ? 0.75 : 0.5;
    }
    return object.labels
        .map((l) => l.confidence)
        .fold<double>(0, (max, c) => c > max ? c : max);
  }

  bool _looksLikeVehicle(DetectedObject object) {
    for (final label in object.labels) {
      final normalized = label.text.toLowerCase();
      for (final hint in _vehicleLabelHints) {
        if (normalized.contains(hint)) return true;
      }
    }
    return false;
  }

  String? _nullableYear(String? raw) {
    if (raw == null) return null;
    final match = RegExp(r'\d{4}').firstMatch(raw.trim());
    return match?.group(0);
  }
}

/// Firestore matches for an identified vehicle.
class CarDetectionLookupResult {
  const CarDetectionLookupResult({
    required this.identification,
    required this.listings,
  });

  final CarIdentificationResult identification;
  final List<Car> listings;
}
