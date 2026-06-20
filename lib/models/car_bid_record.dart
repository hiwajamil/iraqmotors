import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/car_bid_service.dart';

/// A single offer placed on a car listing.
class CarBidRecord {
  const CarBidRecord({
    required this.id,
    required this.amount,
    required this.bidderName,
    required this.bidderPhone,
    this.createdAt,
  });

  final String id;
  final int amount;
  final String bidderName;
  final String bidderPhone;
  final DateTime? createdAt;

  factory CarBidRecord.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final rawAmount = data[CarBidService.bidAmountField];
    final amount = rawAmount is num
        ? rawAmount.toInt()
        : int.tryParse(rawAmount?.toString() ?? '') ?? 0;

    return CarBidRecord(
      id: doc.id,
      amount: amount,
      bidderName: data[CarBidService.bidBidderNameField]?.toString() ?? '',
      bidderPhone: data[CarBidService.bidBidderPhoneField]?.toString() ?? '',
      createdAt: (data[CarBidService.bidCreatedAtField] as Timestamp?)?.toDate(),
    );
  }
}
