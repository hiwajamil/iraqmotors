import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:iq_motors/core/services/firebase_performance_service.dart';
import 'package:iq_motors/features/dashboard/data/services/user_message_service.dart';
import 'package:iq_motors/features/marketplace/domain/models/car_bid_record.dart';
import 'package:iq_motors/features/marketplace/data/services/car_database_service.dart';

class CarBidException implements Exception {
  CarBidException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Thrown when bidding is not allowed on a sold listing.
class CarBidSoldException implements Exception {}

/// Reads and writes car auction bids on Firestore `cars` documents.
class CarBidService {
  CarBidService({
    FirebaseFirestore? firestore,
    UserMessageService? messageService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _messageService = messageService;

  final FirebaseFirestore _firestore;
  final UserMessageService? _messageService;

  static const String highestBidField = 'highestBid';
  static const String lastBidAtField = 'lastBidAt';
  static const String lastBidByField = 'lastBidBy';

  static const String bidsSubcollection = 'bids';
  static const String bidAmountField = 'amount';
  static const String bidBidderNameField = 'bidderName';
  static const String bidBidderPhoneField = 'bidderPhone';
  static const String bidBidderIdField = 'bidderId';
  static const String bidCreatedAtField = 'createdAt';

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
      'status': CarDatabaseService.statusActive,
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
    _ensureBiddingAllowed(snapshot.data());
    return resolveHighestBid(snapshot.data());
  }

  static void _ensureBiddingAllowed(Map<String, dynamic>? data) {
    final status = data?[CarDatabaseService.statusField]?.toString();
    if (status == CarDatabaseService.statusSold) {
      throw CarBidSoldException();
    }
  }

  /// Saves every bid to history. Updates [highestBid] on the car document only
  /// when [newBid] is strictly greater than the current value (or zero/null).
  Future<void> submitValidatedBid({
    required String carId,
    required int newBid,
    String? userId,
    String? bidderName,
    String? bidderPhone,
  }) async {
    return FirebasePerformanceService.instance.traceAsync(
      'submitValidatedBid',
      () async {
        final docRef = _firestore.collection('cars').doc(carId);
        final snapshot = await docRef.get();
        if (!snapshot.exists) {
          throw CarBidException('Car listing not found.');
        }
        _ensureBiddingAllowed(snapshot.data());

        final currentHighest = resolveHighestBid(snapshot.data());

        var resolvedName = bidderName?.trim() ?? '';
        var resolvedPhone = bidderPhone?.trim() ?? '';
        if (userId != null &&
            userId.isNotEmpty &&
            (resolvedName.isEmpty || resolvedPhone.isEmpty)) {
          final userDoc = await _firestore.collection('users').doc(userId).get();
          final userData = userDoc.data();
          if (resolvedName.isEmpty) {
            resolvedName = userData?['displayName']?.toString() ?? '';
          }
          if (resolvedPhone.isEmpty) {
            resolvedPhone = userData?['phone']?.toString() ?? '';
          }
        }

        final batch = _firestore.batch();

        final bidRef = docRef.collection(bidsSubcollection).doc();
        batch.set(bidRef, {
          bidAmountField: newBid,
          bidBidderNameField: resolvedName,
          bidBidderPhoneField: resolvedPhone,
          if (userId != null) bidBidderIdField: userId,
          bidCreatedAtField: FieldValue.serverTimestamp(),
        });

        if (newBid > currentHighest) {
          final updates = <String, dynamic>{
            highestBidField: newBid,
            lastBidAtField: FieldValue.serverTimestamp(),
            if (userId != null) lastBidByField: userId,
          };

          // Soft-close anti-sniping protection: if auction ends within 60s, extend by 2m
          final rawEndTime = snapshot.data()?['auctionEndAt'];
          if (rawEndTime is Timestamp) {
            final endTime = rawEndTime.toDate();
            final now = DateTime.now();
            final diff = endTime.difference(now);
            if (diff.inSeconds > 0 && diff.inSeconds <= 60) {
              final extendedEnd = endTime.add(const Duration(minutes: 2));
              updates['auctionEndAt'] = Timestamp.fromDate(extendedEnd);
            }
          }

          batch.update(docRef, updates);
        }

        try {
          await batch.commit();
        } on FirebaseException catch (e) {
          throw CarBidException(e.message ?? 'Failed to place bid.');
        }

        await _notifyCarOwnerOfBid(
          carData: snapshot.data() ?? const {},
          carId: carId,
          newBid: newBid,
          bidderUserId: userId,
          bidderName: resolvedName,
          bidderPhone: resolvedPhone,
        );
      },
      metrics: {'bid_amount': newBid},
    );
  }

  Future<void> _notifyCarOwnerOfBid({
    required Map<String, dynamic> carData,
    required String carId,
    required int newBid,
    required String? bidderUserId,
    required String bidderName,
    required String bidderPhone,
  }) async {
    final messageService = _messageService;
    if (messageService == null) return;

    final sellerId =
        carData[CarDatabaseService.sellerIdField]?.toString() ?? '';
    if (sellerId.isEmpty || sellerId == bidderUserId) return;

    final carName = _resolveCarName(carData);
    if (carName.isEmpty) return;

    final currencyKey = carData['currencyKey']?.toString();

    try {
      await messageService.sendBidNotification(
        recipientId: sellerId,
        senderName: bidderName,
        senderPhone: bidderPhone,
        carId: carId,
        carName: carName,
        bidAmount: newBid,
        currencyKey: currencyKey,
      );
    } catch (_) {
      // Bid already succeeded — notification failure must not block UX.
    }
  }

  static String _resolveCarName(Map<String, dynamic> data) {
    final brand = data['brandId']?.toString();
    final model = data['modelKey']?.toString();
    final year = data['year']?.toString();
    final parts = [brand, model, year]
        .whereType<String>()
        .where((part) => part.isNotEmpty);
    if (parts.isNotEmpty) return parts.join(' ');

    final make = data['make']?.toString();
    final modelName = data['model']?.toString();
    final demoParts = [make, modelName]
        .whereType<String>()
        .where((part) => part.isNotEmpty);
    if (demoParts.isNotEmpty) return demoParts.join(' ');

    return data['title']?.toString() ?? '';
  }

  /// Lists all bids for [carId], highest price first.
  Future<List<CarBidRecord>> fetchBidHistory(String carId) async {
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot;
      try {
        snapshot = await _firestore
            .collection('cars')
            .doc(carId)
            .collection(bidsSubcollection)
            .orderBy(bidAmountField, descending: true)
            .get();
      } on FirebaseException catch (e) {
        if (e.code != 'failed-precondition') rethrow;
        snapshot = await _firestore
            .collection('cars')
            .doc(carId)
            .collection(bidsSubcollection)
            .get();
      }

      final bids = snapshot.docs.map(CarBidRecord.fromFirestore).toList();
      await _enrichBidderProfiles(bids);
      bids.sort(_compareBidsByAmountDesc);
      return bids;
    } on FirebaseException catch (e) {
      throw CarBidException(e.message ?? 'Failed to load bid history.');
    }
  }

  static int _compareBidsByAmountDesc(CarBidRecord a, CarBidRecord b) {
    final byAmount = b.amount.compareTo(a.amount);
    if (byAmount != 0) return byAmount;

    final aTime = a.createdAt;
    final bTime = b.createdAt;
    if (aTime != null && bTime != null) {
      return bTime.compareTo(aTime);
    }
    return 0;
  }

  Future<void> _enrichBidderProfiles(List<CarBidRecord> bids) async {
    final idsToResolve = <String>{};
    for (final bid in bids) {
      final id = bid.bidderId;
      if (id == null || id.isEmpty) continue;
      if (bid.bidderName.isNotEmpty && bid.bidderPhone.isNotEmpty) continue;
      idsToResolve.add(id);
    }
    if (idsToResolve.isEmpty) return;

    final profiles = await Future.wait(
      idsToResolve.map((uid) async {
        final doc = await _firestore.collection('users').doc(uid).get();
        if (!doc.exists) return MapEntry(uid, const <String, String>{});
        final data = doc.data() ?? {};
        return MapEntry(uid, {
          'name': data['displayName']?.toString() ?? '',
          'phone': data['phone']?.toString() ?? '',
        });
      }),
    );

    final profileById = Map<String, Map<String, String>>.fromEntries(profiles);
    for (var i = 0; i < bids.length; i++) {
      final bid = bids[i];
      final id = bid.bidderId;
      if (id == null) continue;
      final profile = profileById[id];
      if (profile == null) continue;

      final name = bid.bidderName.isNotEmpty
          ? bid.bidderName
          : profile['name'] ?? '';
      final phone = bid.bidderPhone.isNotEmpty
          ? bid.bidderPhone
          : profile['phone'] ?? '';
      if (name == bid.bidderName && phone == bid.bidderPhone) continue;

      bids[i] = CarBidRecord(
        id: bid.id,
        amount: bid.amount,
        bidderName: name,
        bidderPhone: phone,
        bidderId: bid.bidderId,
        createdAt: bid.createdAt,
      );
    }
  }
}
