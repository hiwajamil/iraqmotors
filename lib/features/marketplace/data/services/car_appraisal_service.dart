import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Result of an AI-powered price appraisal for a car listing.
class CarAppraisalResult {
  const CarAppraisalResult({
    required this.minPrice,
    required this.maxPrice,
    required this.currency,
    required this.reasoning,
    required this.confidence,
  });

  /// Estimated minimum market price (IQD).
  final int minPrice;

  /// Estimated maximum market price (IQD).
  final int maxPrice;

  /// Currency code (always 'IQD').
  final String currency;

  /// Short paragraph explaining the estimate.
  final String reasoning;

  /// Confidence level: 'high', 'medium', or 'low'.
  final String confidence;

  String get formattedMin => _formatIqd(minPrice);
  String get formattedMax => _formatIqd(maxPrice);
  String get formattedRange => '$formattedMin – $formattedMax IQD';

  static String _formatIqd(int value) {
    if (value >= 1000000) {
      final m = (value / 1000000).toStringAsFixed(1);
      return '${m}M';
    }
    if (value >= 1000) {
      final k = (value / 1000).toStringAsFixed(0);
      return '${k}K';
    }
    return value.toString();
  }
}

/// Exception thrown when appraisal fails or the Gemini API is unavailable.
class CarAppraisalException implements Exception {
  CarAppraisalException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Uses the Gemini API to estimate the market value of a car in Iraq (IQD).
///
/// Works purely from structured listing data — no image required.
class CarAppraisalService {
  CarAppraisalService({GenerativeModel? model}) : _modelOverride = model;

  final GenerativeModel? _modelOverride;
  GenerativeModel? _cached;

  static const _geminiModel = 'gemini-2.0-flash';
  static const _timeout = Duration(seconds: 15);

  GenerativeModel? get _model {
    if (_modelOverride != null) return _modelOverride;
    final key = dotenv.env['GEMINI_API_KEY']?.trim();
    if (key == null || key.isEmpty) return null;
    return _cached ??= GenerativeModel(model: _geminiModel, apiKey: key);
  }

  /// Estimates the market price of a car in the Iraqi market (IQD).
  ///
  /// Pass the raw listing [carData] map from Firestore.
  Future<CarAppraisalResult> appraise(Map<String, dynamic> carData) async {
    final model = _model;
    if (model == null) {
      throw CarAppraisalException(
        'AI appraisal is not available. Check your GEMINI_API_KEY.',
      );
    }

    final prompt = _buildPrompt(carData);

    try {
      final response = await model
          .generateContent([Content.text(prompt)])
          .timeout(_timeout);

      final text = response.text?.trim();
      if (text == null || text.isEmpty) {
        throw CarAppraisalException('No response from AI. Please try again.');
      }

      return _parseResponse(text);
    } on CarAppraisalException {
      rethrow;
    } catch (e) {
      throw CarAppraisalException('Appraisal failed: $e');
    }
  }

  String _buildPrompt(Map<String, dynamic> car) {
    final brand = car['brandId'] ?? car['brand'] ?? 'Unknown';
    final model = car['modelKey'] ?? car['model'] ?? 'Unknown';
    final year = car['year'] ?? 'Unknown';
    final condition = car['conditionKey'] ?? 'Unknown';
    final mileage = car['mileageValue'] ?? car['mileage'] ?? 'Unknown';
    final fuel = car['fuelKey'] ?? 'Unknown';
    final transmission = car['transmissionKey'] ?? 'Unknown';
    final color = car['colorKey'] ?? 'Unknown';
    final trim = car['trim'] ?? '';
    final importCountry = car['importCountryKey'] ?? '';
    final engineSize = car['engineSizeKey'] ?? '';
    final cylinders = car['cylindersKey'] ?? '';

    return '''
You are a car market expert specializing in Iraq (Iraqi Dinar - IQD market).

Estimate the fair market value of this car as if it were being sold in Iraq today:

Brand: $brand
Model: $model
Year: $year
Condition: $condition
Mileage: $mileage km
Fuel: $fuel
Transmission: $transmission
Color: $color
Trim: $trim
Import Country: $importCountry
Engine Size: $engineSize
Cylinders: $cylinders

Respond with ONLY valid JSON in this exact format, no markdown:
{
  "min_price": 12000000,
  "max_price": 15000000,
  "currency": "IQD",
  "confidence": "high",
  "reasoning": "Short 1-2 sentence explanation of the estimate."
}

Rules:
- Prices must be in IQD (Iraqi Dinar). Typical range is 5M to 150M+ IQD.
- confidence must be one of: "high", "medium", "low"
- reasoning must be in English, max 2 sentences
''';
  }

  CarAppraisalResult _parseResponse(String text) {
    // Strip markdown code fences if present
    final cleaned = text
        .replaceAll(RegExp(r'```json\s*'), '')
        .replaceAll(RegExp(r'```\s*'), '')
        .trim();

    try {
      final json = jsonDecode(cleaned) as Map<String, dynamic>;

      final min = _toInt(json['min_price']);
      final max = _toInt(json['max_price']);
      if (min == null || max == null || min <= 0 || max <= 0) {
        throw const FormatException('Invalid price');
      }

      return CarAppraisalResult(
        minPrice: min,
        maxPrice: max > min ? max : min + (min ~/ 5),
        currency: json['currency']?.toString() ?? 'IQD',
        reasoning: json['reasoning']?.toString() ?? '',
        confidence: json['confidence']?.toString() ?? 'medium',
      );
    } catch (_) {
      throw CarAppraisalException(
        'Could not parse AI response. Please try again.',
      );
    }
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString());
  }
}
