import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:image/image.dart' as img;
import 'package:image_pixels/image_pixels.dart' show ImgDetails;

import 'package:iq_motors/core/localization/filter_l10n.dart';
import 'package:iq_motors/shared/data/add_car_form_options.dart';
import 'package:iq_motors/shared/data/car_models_by_brand.dart';
import 'package:iq_motors/shared/data/dummy_brands.dart';
import 'package:iq_motors/shared/models/account_type.dart';
import 'package:iq_motors/shared/models/car_brand.dart';
import 'package:iq_motors/features/admin/data/services/user_usage_service.dart';

/// Kurdish messages for the add-car photo validation flow.
abstract final class CarVisionMessages {
  static const notAVehicle = 'تکایە تەنها وێنەی ئۆتۆمبێل دابنێ.';
  static const inconsistentPhotos =
      'تکایە دڵنیابەرەوە لە وێنەکان هی هەمان ئۆتۆمبێل بن.';
  static const aiAutoFillSuccess = 'AI-یەکە زانیارییەکانی دۆزییەوە';
}

enum CarVisionFailure {
  notAVehicle,
  inconsistentPhotos,
}

class CarVisionException implements Exception {
  CarVisionException(this.failure, {this.message});

  final CarVisionFailure failure;
  final String? message;

  String get userMessage => switch (failure) {
        CarVisionFailure.notAVehicle => CarVisionMessages.notAVehicle,
        CarVisionFailure.inconsistentPhotos =>
          CarVisionMessages.inconsistentPhotos,
      };

  @override
  String toString() => message ?? userMessage;
}

/// App form keys mapped from Gemini analysis.
class CarVisionFormSuggestion {
  const CarVisionFormSuggestion({
    this.brandId,
    this.modelKey,
    this.colorKey,
  });

  final String? brandId;
  final String? modelKey;
  final String? colorKey;

  bool get hasAny =>
      brandId != null || modelKey != null || colorKey != null;
}

enum CarVisionAutoFillStatus {
  quotaExceeded,
  unavailable,
  noResults,
  success,
}

/// Result of a quota-gated Gemini auto-fill attempt (after on-device validation).
class CarVisionAutoFillOutcome {
  const CarVisionAutoFillOutcome({
    required this.status,
    this.suggestion,
  });

  final CarVisionAutoFillStatus status;
  final CarVisionFormSuggestion? suggestion;

  bool get shouldShowSuccessMessage =>
      status == CarVisionAutoFillStatus.success &&
      (suggestion?.hasAny ?? false);
}

/// On-device photo validation for the add-car wizard (ML Kit + histograms).
class CarVisionService {
  CarVisionService({
    ObjectDetector? objectDetector,
    ImageLabeler? imageLabeler,
    GenerativeModel? generativeModel,
    UserUsageService? usageService,
  })  : _objectDetectorOverride = objectDetector,
        _imageLabelerOverride = imageLabeler,
        _generativeModelOverride = generativeModel,
        _usageService = usageService ?? UserUsageService();

  final ObjectDetector? _objectDetectorOverride;
  final ImageLabeler? _imageLabelerOverride;
  final GenerativeModel? _generativeModelOverride;
  final UserUsageService _usageService;

  ObjectDetector? _cachedObjectDetector;
  ImageLabeler? _cachedImageLabeler;
  GenerativeModel? _cachedGenerativeModel;

  static const _geminiModel = 'gemini-2.0-flash';
  static const _analyzePrompt =
      "Identify the brand, model, and color of the car in this image. "
      "Return the result in JSON format: {'brand': '', 'model': '', 'color': ''}.";

  static const _vehicleLabels = {
    'car',
    'vehicle',
    'land vehicle',
    'motor vehicle',
    'automobile',
    'sedan',
    'suv',
    'truck',
    'pickup truck',
    'minivan',
    'van',
    'sports car',
    'coupe',
    'hatchback',
    'bus',
    'motorcycle',
  };

  static const _minLabelConfidence = 0.45;
  static const _minObjectAreaFraction = 0.06;
  static const _histogramMismatchThreshold = 0.55;
  static const _histogramSampleSize = 64;
  static const _histogramBins = 16;

  bool get _mlKitAvailable =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  ObjectDetector get _objectDetector {
    final override = _objectDetectorOverride;
    if (override != null) return override;
    return _cachedObjectDetector ??= ObjectDetector(
      options: ObjectDetectorOptions(
        mode: DetectionMode.single,
        classifyObjects: false,
        multipleObjects: true,
      ),
    );
  }

  ImageLabeler get _imageLabeler {
    final override = _imageLabelerOverride;
    if (override != null) return override;
    return _cachedImageLabeler ??= ImageLabeler(
      options: ImageLabelerOptions(confidenceThreshold: _minLabelConfidence),
    );
  }

  GenerativeModel? get _generativeModel {
    final override = _generativeModelOverride;
    if (override != null) return override;

    final apiKey = dotenv.env['GEMINI_API_KEY']?.trim();
    if (apiKey == null || apiKey.isEmpty) return null;

    return _cachedGenerativeModel ??= GenerativeModel(
      model: _geminiModel,
      apiKey: apiKey,
    );
  }

  /// Sends [imageFile] to Gemini and returns brand/model/color strings.
  /// Internal — prefer [autoFillAfterValidation] for quota-aware calls.
  Future<Map<String, String>> analyzeCarImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    return analyzeCarImageBytes(
      bytes,
      mimeType: _mimeTypeForPath(imageFile.path),
    );
  }

  /// Sends raw image [bytes] to Gemini (camera crops, in-memory frames).
  Future<Map<String, String>> analyzeCarImageBytes(
    Uint8List bytes, {
    String mimeType = 'image/jpeg',
  }) async {
    try {
      final model = _generativeModel;
      if (model == null) return const {};

      final response = await model.generateContent([
        Content.multi([
          TextPart(_analyzePrompt),
          DataPart(mimeType, bytes),
        ]),
      ]);

      final text = response.text?.trim();
      if (text == null || text.isEmpty) return const {};

      final parsed = _parseJsonResponse(text);
      if (parsed == null) return const {};

      return {
        'brand': _stringOrEmpty(parsed['brand']),
        'model': _stringOrEmpty(parsed['model']),
        'color': _stringOrEmpty(parsed['color']),
      };
    } catch (_) {
      return const {};
    }
  }

  /// Maps raw Gemini strings to catalog keys used by the add-car form.
  CarVisionFormSuggestion mapAnalysisToFormKeys(Map<String, String> analysis) {
    final brandName = _nullableString(analysis['brand']);
    final modelName = _nullableString(analysis['model']);
    final colorName = _nullableString(analysis['color']);

    final brand = brandName != null ? _matchBrand(brandName) : null;
    final modelKey = brand != null && modelName != null
        ? _matchModel(brand, modelName)
        : null;
    final colorKey =
        colorName != null ? _matchColorKey(colorName) : null;

    return CarVisionFormSuggestion(
      brandId: brand?.id,
      modelKey: modelKey,
      colorKey: colorKey,
    );
  }

  /// Runs Gemini auto-fill only after on-device validation and quota checks.
  ///
  /// Call this only when [validatePhotoUpload] has already succeeded.
  Future<CarVisionAutoFillOutcome> autoFillAfterValidation({
    required File imageFile,
    required String userId,
    AccountType accountType = AccountType.individual,
  }) async {
    final canUse = await _usageService.canUseAiAutoFill(
      userId: userId,
      accountType: accountType,
    );
    if (!canUse) {
      return const CarVisionAutoFillOutcome(
        status: CarVisionAutoFillStatus.quotaExceeded,
      );
    }

    if (_generativeModel == null) {
      return const CarVisionAutoFillOutcome(
        status: CarVisionAutoFillStatus.unavailable,
      );
    }

    final analysis = await analyzeCarImage(imageFile);
    final suggestion = mapAnalysisToFormKeys(analysis);
    if (!suggestion.hasAny) {
      return const CarVisionAutoFillOutcome(
        status: CarVisionAutoFillStatus.noResults,
      );
    }

    await _usageService.recordAiAutoFillUsage(userId);
    return CarVisionAutoFillOutcome(
      status: CarVisionAutoFillStatus.success,
      suggestion: suggestion,
    );
  }

  /// Validates [imagePath] with on-device object detection + labeling.
  ///
  /// Skips validation on web/desktop where ML Kit is unavailable.
  Future<bool> validateIsVehicle(String imagePath) async {
    if (!_mlKitAvailable) return true;

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final objects = await _objectDetector.processImage(inputImage);
      if (!_hasProminentObject(objects, inputImage)) {
        return false;
      }

      final labels = await _imageLabeler.processImage(inputImage);
      return _containsVehicleLabel(labels);
    } catch (e, stackTrace) {
      debugPrint('Vision validation error (ML Kit): $e');
      debugPrint('$stackTrace');
      // Do not block uploads when on-device vision fails unexpectedly.
      return true;
    }
  }

  /// Compares [newImagePath] against [firstImagePath] using color histograms.
  Future<bool> validateSameCar({
    required String newImagePath,
    required String? firstImagePath,
  }) async {
    if (firstImagePath == null ||
        firstImagePath == newImagePath ||
        _isRemoteUrl(firstImagePath) ||
        kIsWeb ||
        firstImagePath.startsWith('blob:') ||
        newImagePath.startsWith('blob:')) {
      return true;
    }

    final referenceHist = await _computeColorHistogram(firstImagePath);
    final newHist = await _computeColorHistogram(newImagePath);
    if (referenceHist == null || newHist == null) return true;

    final similarity = _histogramSimilarity(referenceHist, newHist);
    return similarity >= (1 - _histogramMismatchThreshold);
  }

  /// Runs vehicle validation and optional consistency check before accepting a photo.
  Future<void> validatePhotoUpload({
    required String imagePath,
    required String? firstImagePath,
  }) async {
    final isVehicle = await validateIsVehicle(imagePath);
    if (!isVehicle) {
      throw CarVisionException(CarVisionFailure.notAVehicle);
    }

    final sameCar = await validateSameCar(
      newImagePath: imagePath,
      firstImagePath: firstImagePath,
    );
    if (!sameCar) {
      throw CarVisionException(CarVisionFailure.inconsistentPhotos);
    }
  }

  Future<void> dispose() async {
    if (_objectDetectorOverride == null) {
      await _cachedObjectDetector?.close();
    }
    if (_imageLabelerOverride == null) {
      await _cachedImageLabeler?.close();
    }
  }

  bool _hasProminentObject(
    List<DetectedObject> objects,
    InputImage inputImage,
  ) {
    if (objects.isEmpty) return false;

    final metadata = inputImage.metadata;
    final imageWidth = metadata?.size.width ?? 0;
    final imageHeight = metadata?.size.height ?? 0;
    if (imageWidth <= 0 || imageHeight <= 0) {
      return objects.isNotEmpty;
    }

    final imageArea = imageWidth * imageHeight;
    for (final object in objects) {
      final box = object.boundingBox;
      final objectArea = box.width * box.height;
      if (objectArea / imageArea >= _minObjectAreaFraction) {
        return true;
      }
    }
    return false;
  }

  bool _containsVehicleLabel(List<ImageLabel> labels) {
    for (final label in labels) {
      if (label.confidence < _minLabelConfidence) continue;

      final normalized = label.label.toLowerCase().trim();
      if (_vehicleLabels.contains(normalized)) return true;

      for (final vehicle in _vehicleLabels) {
        if (normalized.contains(vehicle)) return true;
      }
    }
    return false;
  }

  /// Builds a normalized RGB histogram using [image] for decode/resize and
  /// RGBA [ByteData] sampling aligned with [ImgDetails.pixelColorAt].
  Future<List<double>?> _computeColorHistogram(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      final resized = img.copyResize(
        decoded,
        width: _histogramSampleSize,
        height: _histogramSampleSize,
        interpolation: img.Interpolation.average,
      );

      final pngBytes = Uint8List.fromList(img.encodePng(resized));
      final rgba = await _loadRgbaBytes(pngBytes);
      if (rgba == null) return _histogramFromImagePackage(resized);

      return _histogramFromRgba(
        rgba,
        resized.width,
        resized.height,
      );
    } catch (_) {
      return null;
    }
  }

  Future<ByteData?> _loadRgbaBytes(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
  }

  List<double> _histogramFromRgba(ByteData rgba, int width, int height) {
    final bins = _histogramBins;
    final hist = List<double>.filled(bins * 3, 0);

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final byteOffset = 4 * (x + (y * width));
        final rgbaColor = rgba.getUint32(byteOffset);
        final r = rgbaColor & 0xFF;
        final g = (rgbaColor >> 8) & 0xFF;
        final b = (rgbaColor >> 16) & 0xFF;

        hist[(r >> 4).clamp(0, bins - 1)]++;
        hist[bins + (g >> 4).clamp(0, bins - 1)]++;
        hist[bins * 2 + (b >> 4).clamp(0, bins - 1)]++;
      }
    }

    return _normalizeHistogram(hist);
  }

  List<double> _histogramFromImagePackage(img.Image resized) {
    final bins = _histogramBins;
    final hist = List<double>.filled(bins * 3, 0);

    for (var y = 0; y < resized.height; y++) {
      for (var x = 0; x < resized.width; x++) {
        final pixel = resized.getPixel(x, y);
        hist[(pixel.r.toInt() >> 4).clamp(0, bins - 1)]++;
        hist[bins + (pixel.g.toInt() >> 4).clamp(0, bins - 1)]++;
        hist[bins * 2 + (pixel.b.toInt() >> 4).clamp(0, bins - 1)]++;
      }
    }

    return _normalizeHistogram(hist);
  }

  List<double> _normalizeHistogram(List<double> hist) {
    final total = hist.fold<double>(0, (sum, value) => sum + value);
    if (total <= 0) return hist;
    return hist.map((value) => value / total).toList();
  }

  double _histogramSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length || a.isEmpty) return 1;
    var intersection = 0.0;
    for (var i = 0; i < a.length; i++) {
      intersection += a[i] < b[i] ? a[i] : b[i];
    }
    return intersection;
  }

  bool _isRemoteUrl(String path) =>
      path.startsWith('http://') || path.startsWith('https://');

  Map<String, dynamic>? _parseJsonResponse(String text) {
    try {
      return jsonDecode(text) as Map<String, dynamic>;
    } catch (_) {
      final match = RegExp(r'\{[\s\S]*\}').firstMatch(text);
      if (match == null) return null;
      try {
        return jsonDecode(match.group(0)!) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    }
  }

  String _stringOrEmpty(dynamic value) {
    if (value == null) return '';
    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return '';
    return text;
  }

  String? _nullableString(String? value) {
    if (value == null) return null;
    final text = value.trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return null;
    return text;
  }

  String _mimeTypeForPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  CarBrand? _matchBrand(String raw) {
    final normalized = _normalize(raw);
    for (final brand in dummyBrands) {
      if (_normalize(brand.id) == normalized ||
          _normalize(brand.nameEnglish) == normalized ||
          _normalize(brand.nameKurdish) == normalized) {
        return brand;
      }
    }
    for (final brand in dummyBrands) {
      final en = _normalize(brand.nameEnglish);
      if (en.contains(normalized) || normalized.contains(en)) {
        return brand;
      }
    }
    return null;
  }

  String? _matchModel(CarBrand brand, String raw) {
    final models = CarModelsByBrand.modelsForBrand(brand);
    if (models == null || models.isEmpty) return null;

    final normalized = _normalize(raw);
    for (final model in models) {
      if (_normalize(model.id) == normalized ||
          _normalize(model.en) == normalized ||
          _normalize(model.ku) == normalized ||
          _normalize(model.ar) == normalized) {
        return model.id;
      }
    }
    for (final model in models) {
      final en = _normalize(model.en);
      if (en.contains(normalized) || normalized.contains(en)) {
        return model.id;
      }
    }
    return null;
  }

  String? _matchColorKey(String raw) {
    final normalized = _normalize(raw);

    const aliases = <String, List<String>>{
      FilterOptionKeys.colorBlack: ['black', 'dark', 'charcoal'],
      FilterOptionKeys.colorWhite: ['white', 'pearl', 'ivory'],
      FilterOptionKeys.colorSilver: ['silver', 'chrome'],
      FilterOptionKeys.colorGray: ['gray', 'grey', 'graphite'],
      FilterOptionKeys.colorRed: ['red', 'maroon', 'burgundy'],
      FilterOptionKeys.colorBlue: ['blue', 'navy', 'azure'],
      FilterOptionKeys.colorGreen: ['green', 'olive'],
    };

    for (final key in AddCarFormOptions.colorKeys) {
      if (_normalize(key.replaceAll('_', ' ')) == normalized) return key;
    }

    for (final entry in aliases.entries) {
      for (final alias in entry.value) {
        if (normalized == alias || normalized.contains(alias)) {
          return entry.key;
        }
      }
    }
    return null;
  }

  String _normalize(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\u0600-\u06FF]+'), '');
}
