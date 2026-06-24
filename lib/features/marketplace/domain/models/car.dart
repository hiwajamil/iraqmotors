import 'package:iq_motors/shared/data/add_car_form_options.dart';
import 'package:iq_motors/shared/data/car_models_by_brand.dart';
import 'package:iq_motors/shared/data/dummy_brands.dart';
import 'package:iq_motors/features/marketplace/data/services/car_bid_service.dart';

/// Parsed car listing for the public home feed and detail views.
class Car {
  const Car({required this.id, required this.data});

  final String id;
  final Map<String, dynamic> data;

  Map<String, dynamic> toMap() => {...data, 'id': id};

  /// Parses a Firestore car document into a display-ready [Car], or `null` on failure.
  static Car? fromMap(String docId, Map<String, dynamic> raw) {
    try {
      final data = Map<String, dynamic>.from(raw);

      final imageUrls = _imageUrlsFromData(data);
      final imageUrl = imageUrls.isNotEmpty
          ? imageUrls.first
          : (data['imageUrl']?.toString() ?? '');

      final make = _resolveMake(data);
      final model = _resolveModel(data);
      final price = _formatPrice(data);
      final mileage = _formatMileage(data);

      data['imageUrls'] = imageUrls;
      if (imageUrl.isNotEmpty) {
        data['imageUrl'] = imageUrl;
      }
      if (make.isNotEmpty) {
        data['make'] = make;
      }
      if (model.isNotEmpty) {
        data['model'] = model;
      }
      if (price.isNotEmpty) {
        data['price'] = price;
      }
      if (mileage.isNotEmpty) {
        data['mileage'] = mileage;
      }

      final highestBid = _coerceInt(data[CarBidService.highestBidField]);
      if (highestBid != null) {
        data[CarBidService.highestBidField] = highestBid;
      }
      final priceValue = _coerceNum(data['priceValue']);
      if (priceValue != null) {
        data['priceValue'] = priceValue;
      }
      final mileageValue = _coerceNum(data['mileageValue']);
      if (mileageValue != null) {
        data['mileageValue'] = mileageValue;
      }

      return Car(id: docId, data: data);
    } catch (e) {
      // ignore: avoid_print
      print('Error parsing car $docId: $e');
      return null;
    }
  }

  static String _resolveMake(Map<String, dynamic> data) {
    final existing = data['make']?.toString().trim();
    if (existing != null && existing.isNotEmpty) return existing;

    final brandId = data['brandId']?.toString();
    if (brandId == null || brandId.isEmpty) return '';

    for (final brand in dummyBrands) {
      if (brand.id == brandId) {
        return brand.displayName('en');
      }
    }
    return brandId;
  }

  static String _resolveModel(Map<String, dynamic> data) {
    final existing = data['model']?.toString().trim();
    if (existing != null && existing.isNotEmpty) return existing;

    final brandId = data['brandId']?.toString();
    final modelKey = data['modelKey']?.toString();
    if (brandId == null || modelKey == null) return '';

    for (final brand in dummyBrands) {
      if (brand.id == brandId) {
        final label = CarModelsByBrand.labelForModel(brand, modelKey, 'en');
        if (label != null && label.isNotEmpty) {
          final year = data['year']?.toString();
          final trim = data['trim']?.toString();
          return [
            label,
            if (year != null && year.isNotEmpty) year,
            if (trim != null && trim.isNotEmpty) trim,
          ].join(' ');
        }
        break;
      }
    }

    final parts = [modelKey, data['year']?.toString(), data['trim']?.toString()]
        .whereType<String>()
        .where((part) => part.isNotEmpty);
    return parts.join(' ');
  }

  static String _formatPrice(Map<String, dynamic> data) {
    final displayPrice = data['price']?.toString().trim();
    if (displayPrice != null && displayPrice.isNotEmpty) {
      return displayPrice;
    }

    final amount = _coerceInt(data['priceValue']);
    if (amount == null || amount <= 0) return '';

    final currencyKey =
        data['currencyKey']?.toString() ?? AddCarFormOptions.defaultCurrencyKey;
    final symbol = AddCarFormOptions.currencySymbol(currencyKey);
    final formatted = amount.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
    return '$symbol$formatted';
  }

  static String _formatMileage(Map<String, dynamic> data) {
    final existing = data['mileage']?.toString().trim();
    if (existing != null && existing.isNotEmpty) return existing;

    final amount = _coerceInt(data['mileageValue']);
    if (amount == null) return '';

    final unitKey = data['mileageUnit']?.toString() ?? 'km';
    final unit = unitKey == 'mi' ? 'mi' : 'km';
    final formatted = amount.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
    return '$formatted $unit';
  }

  static List<String> _imageUrlsFromData(Map<String, dynamic> data) {
    for (final key in ['imageUrls', 'photos', 'images']) {
      final urls = _urlListFromField(data[key]);
      if (urls.isNotEmpty) return urls;
    }
    final single = data['imageUrl']?.toString().trim();
    if (single != null && single.isNotEmpty) return [single];
    return const [];
  }

  static List<String> _urlListFromField(dynamic value) {
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isNotEmpty ? [trimmed] : const [];
    }
    if (value is List) {
      return value
          .map((e) => e?.toString().trim() ?? '')
          .where((url) => url.isNotEmpty)
          .toList();
    }
    return const [];
  }

  static int? _coerceInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static num? _coerceNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    return num.tryParse(value.toString());
  }
}
