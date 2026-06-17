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

  /// Ensures a car document exists before bidding (seeds demo listings when needed).
  Future<void> ensureCarListingForBid({
    required String carId,
    Map<String, dynamic>? seedData,
  }) async {
    final docRef = _firestore.collection('cars').doc(carId);
    final snapshot = await docRef.get();
    if (snapshot.exists) return;

    if (seedData == null) {
      throw CarBidException('Car listing not found.');
    }

    final data = Map<String, dynamic>.from(seedData)..remove('id');
    final imageUrl = data.remove('imageUrl')?.toString();
    final imageUrls = _urlListFromField(data['imageUrls']);
    if (imageUrls.isEmpty && imageUrl != null && imageUrl.isNotEmpty) {
      data['imageUrls'] = [imageUrl];
    }

    await docRef.set({
      ...data,
      'status': 'active',
      highestBidField: _initialHighestBidFromSeed(data),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static int _initialHighestBidFromSeed(Map<String, dynamic> data) {
    final fromBid = parseBidAmount(data['latestBid']?.toString() ?? '');
    if (fromBid != null && fromBid > 0) return fromBid;

    final fromPrice = parseBidAmount(data['price']?.toString() ?? '');
    if (fromPrice != null && fromPrice > 0) return fromPrice;

    final priceValue = data['priceValue'];
    if (priceValue is num) return priceValue.toInt();

    return 0;
  }

  static List<String> _urlListFromField(dynamic value) {
    if (value is! List) return const [];
    return value.map((e) => e.toString()).where((u) => u.isNotEmpty).toList();
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
    // ignore: avoid_print
    print('Attempting to submit offer for carId: $carId');

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
