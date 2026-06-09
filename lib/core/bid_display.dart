import '../data/add_car_form_options.dart';
import '../services/car_bid_service.dart';

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

  /// Display label for the latest bid row on a card.
  static String latestBidLabel({
    required Map<String, dynamic> car,
    Map<String, dynamic>? firestoreData,
  }) {
    final currencyKey =
        firestoreData?['currencyKey']?.toString() ??
        car['currencyKey']?.toString() ??
        AddCarFormOptions.defaultCurrencyKey;

    final highestBid = CarBidService.resolveHighestBid(firestoreData);
    if (highestBid > 0) {
      return formatAmount(highestBid, currencyKey: currencyKey);
    }

    final staticBid = car['latestBid']?.toString();
    if (staticBid != null && staticBid.isNotEmpty) {
      return staticBid;
    }

    final priceValue = firestoreData?['priceValue'];
    if (priceValue is num && priceValue.toInt() > 0) {
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
