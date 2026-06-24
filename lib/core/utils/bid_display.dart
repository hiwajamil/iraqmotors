import 'package:iq_motors/shared/data/add_car_form_options.dart';
import 'package:iq_motors/features/marketplace/data/services/car_bid_service.dart';

/// Formats bid amounts for listing cards and detail views.
abstract final class BidDisplay {
  static String formatAmount(
    int amount, {
    String currencyKey = AddCarFormOptions.defaultCurrencyKey,
  }) {
    if (amount <= 0) return '';
    final symbol = AddCarFormOptions.currencySymbol(currencyKey);
    final formatted = amount.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
    return '$symbol$formatted';
  }

  /// Formatted [highestBid] from Firestore — public cards and owner dashboard.
  ///
  /// Returns `null` when no offers exist yet (amount ≤ 0).
  static String? highestBidLabel({
    required Map<String, dynamic> car,
    Map<String, dynamic>? firestoreData,
  }) {
    final currencyKey =
        firestoreData?['currencyKey']?.toString() ??
        car['currencyKey']?.toString() ??
        AddCarFormOptions.defaultCurrencyKey;

    final source = firestoreData ?? car;
    final highestBid = CarBidService.resolveHighestBid(source);
    if (highestBid <= 0) return null;

    return formatAmount(highestBid, currencyKey: currencyKey);
  }

  /// Display label for the latest bid row on a card (includes static fallbacks).
  static String latestBidLabel({
    required Map<String, dynamic> car,
    Map<String, dynamic>? firestoreData,
  }) {
    final fromHighest = highestBidLabel(
      car: car,
      firestoreData: firestoreData,
    );
    if (fromHighest != null && fromHighest.isNotEmpty) {
      return fromHighest;
    }

    final staticBid = car['latestBid']?.toString();
    if (staticBid != null && staticBid.isNotEmpty) {
      return staticBid;
    }

    final priceValue = firestoreData?['priceValue'];
    if (priceValue is num && priceValue.toInt() > 0) {
      final currencyKey =
          firestoreData?['currencyKey']?.toString() ??
          car['currencyKey']?.toString() ??
          AddCarFormOptions.defaultCurrencyKey;
      return formatAmount(priceValue.toInt(), currencyKey: currencyKey);
    }

    return car['price']?.toString() ?? '';
  }

  /// Numeric highest bid used for validation (Firestore first, then static).
  static int highestBidAmount({
    required Map<String, dynamic> car,
    Map<String, dynamic>? firestoreData,
  }) {
    final fromFirestore = CarBidService.resolveHighestBid(firestoreData);
    if (fromFirestore > 0) return fromFirestore;

    final staticBid = car['latestBid']?.toString() ?? car['price']?.toString();
    if (staticBid != null) {
      return CarBidService.parseBidAmount(staticBid) ?? 0;
    }

    final priceValue = firestoreData?['priceValue'];
    if (priceValue is num) return priceValue.toInt();

    return CarBidService.parseBidAmount(car['price']?.toString() ?? '') ?? 0;
  }
}
