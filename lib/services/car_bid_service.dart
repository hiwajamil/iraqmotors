import 'package:cloud_firestore/cloud_firestore.dart';

class CarBidException implements Exception {
  CarBidException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Thrown when [newBid] is not strictly greater than the current highest bid.
class CarBidTooLowException implements Exception {}

/// Reads and writes car auction bids on Firestore `cars` documents.
class CarBidService {
  CarBidService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String highestBidField = 'highestBid';
  static const String lastBidAtField = 'lastBidAt';
  static const String lastBidByField = 'lastBidBy';

  /// One-time read of the car document — used when placing a bid (1 read).
  Future<DocumentSnapshot<Map<String, dynamic>>> fetchCarDoc(String carId) {
    return _firestore.collection('cars').doc(carId).get();
  }

  /// Parses a user-entered bid string into a whole-number amount.
  static int? parseBidAmount(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.isEmpty) return null;
    return int.tryParse(cleaned);
  }

  /// Resolves the numeric highest bid from Firestore data, defaulting to [fallback].
  static int resolveHighestBid(
    Map<String, dynamic>? data, {
    int fallback = 0,
  }) {
    if (data == null) return fallback;
    final raw = data[highestBidField];
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '') ?? fallback;
  }

  /// Fetches the latest highest bid (1 Firestore read).
  Future<int> fetchHighestBid(String carId) async {
    final snapshot = await fetchCarDoc(carId);
    if (!snapshot.exists) {
      throw CarBidException('Car listing not found.');
    }
    return resolveHighestBid(snapshot.data());
  }

  /// Validates against the latest [highestBid], then writes the new bid (1 write).
  Future<void> submitValidatedBid({
    required String carId,
    required int newBid,
    required int highestBid,
    String? userId,
  }) async {
    if (newBid <= highestBid) {
      throw CarBidTooLowException();
    }

    final docRef = _firestore.collection('cars').doc(carId);

    try {
      await docRef.update({
        highestBidField: newBid,
        lastBidAtField: FieldValue.serverTimestamp(),
        if (userId != null) lastBidByField: userId,
      });
    } on FirebaseException catch (e) {
      throw CarBidException(e.message ?? 'Failed to place bid.');
    }
  }
}
