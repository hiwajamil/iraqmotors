import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:iq_motors/core/services/firebase_performance_service.dart';
import 'package:iq_motors/features/admin/domain/models/activity_log.dart';
import 'package:iq_motors/features/marketplace/domain/models/car.dart';
import 'package:iq_motors/features/admin/data/services/activity_log_service.dart';
import 'package:iq_motors/features/marketplace/data/services/car_bid_service.dart';
import 'package:iq_motors/features/marketplace/data/services/car_filter_service.dart';
import 'package:iq_motors/features/marketplace/domain/models/user_car_interest.dart';
import 'package:iq_motors/features/storage/data/services/r2_storage_service.dart';

class CarDatabaseException implements Exception {
  CarDatabaseException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Persists car listing documents to Firestore.
class CarDatabaseService {
  CarDatabaseService({
    FirebaseFirestore? firestore,
    R2StorageService? r2Storage,
    ActivityLogService? activityLog,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _r2 = r2Storage ?? R2StorageService(),
       _activityLog = activityLog ?? ActivityLogService();

  final FirebaseFirestore _firestore;
  final R2StorageService _r2;
  final ActivityLogService _activityLog;

  static const String sellerIdField = 'sellerId';
  static const String likedByUsersField = 'likedByUsers';
  static const String statusField = 'status';
  static const String statusPending = 'pending';
  static const String statusActive = 'active';
  static const String statusRejected = 'rejected';
  static const String statusExpired = 'expired';
  static const String statusSold = 'sold';
  static const String statusDraft = 'draft';

  /// Statuses shown on the public home feed (live listings + sold).
  static const List<String> publicFeedStatuses = [statusActive, statusSold];
  static const String accountTypeField = 'accountType';
  static const String accountTypeShowroom = 'showroom';

  /// Lists car ads published by [currentUserId] (`sellerId` field).
  Future<List<Map<String, dynamic>>> fetchUserAds(String currentUserId) async {
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot;
      try {
        snapshot = await _firestore
            .collection('cars')
            .where(sellerIdField, isEqualTo: currentUserId)
            .orderBy('createdAt', descending: true)
            .get();
      } on FirebaseException catch (e) {
        if (e.code != 'failed-precondition') rethrow;
        snapshot = await _firestore
            .collection('cars')
            .where(sellerIdField, isEqualTo: currentUserId)
            .get();
      }
      return _mapsFromQuery(snapshot);
    } on FirebaseException catch (e) {
      throw CarDatabaseException(e.message ?? 'Failed to fetch user ads.');
    } catch (e) {
      throw CarDatabaseException('Failed to fetch user ads: $e');
    }
  }

  /// Lists car ads favorited by [currentUserId] (`likedByUsers` array).
  Future<List<Map<String, dynamic>>> fetchFavoriteAds(
    String currentUserId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('cars')
          .where(likedByUsersField, arrayContains: currentUserId)
          .get();
      return _mapsFromQuery(snapshot);
    } on FirebaseException catch (e) {
      throw CarDatabaseException(e.message ?? 'Failed to fetch favorite ads.');
    } catch (e) {
      throw CarDatabaseException('Failed to fetch favorite ads: $e');
    }
  }

  /// Favorite listing IDs only — skips [Car.fromMap] / full map materialization.
  Future<Set<String>> fetchFavoriteAdIds(String currentUserId) async {
    try {
      final snapshot = await _firestore
          .collection('cars')
          .where(likedByUsersField, arrayContains: currentUserId)
          .get();
      return snapshot.docs.map((doc) => doc.id).toSet();
    } on FirebaseException catch (e) {
      throw CarDatabaseException(e.message ?? 'Failed to fetch favorite ads.');
    } catch (e) {
      throw CarDatabaseException('Failed to fetch favorite ads: $e');
    }
  }

  /// Adds [userId] to a car's `likedByUsers` array.
  ///
  /// When the document does not exist yet (e.g. demo listings), [seedData] is
  /// written so the favorite can appear in the user dashboard.
  Future<void> favoriteCarAd({
    required String adId,
    required String userId,
    Map<String, dynamic>? seedData,
  }) async {
    try {
      final docRef = _firestore.collection('cars').doc(adId);
      final snapshot = await docRef.get();
      if (snapshot.exists) {
        await docRef.update({
          likedByUsersField: FieldValue.arrayUnion([userId]),
        });
      } else if (seedData != null) {
        final data = Map<String, dynamic>.from(seedData)..remove('id');
        final imageUrl = data.remove('imageUrl')?.toString();
        final imageUrls = _urlListFromField(data['imageUrls']);
        if (imageUrls.isEmpty && imageUrl != null && imageUrl.isNotEmpty) {
          data['imageUrls'] = [imageUrl];
        }
        await docRef.set({
          ...data,
          likedByUsersField: [userId],
          statusField: statusActive,
          CarBidService.highestBidField: 0,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        throw CarDatabaseException('Car listing not found.');
      }
    } on FirebaseException catch (e) {
      throw CarDatabaseException(e.message ?? 'Failed to save favorite.');
    } catch (e) {
      if (e is CarDatabaseException) rethrow;
      throw CarDatabaseException('Failed to save favorite: $e');
    }
  }

  /// Removes [userId] from a car's `likedByUsers` array (un-favorite).
  Future<void> unfavoriteCarAd({
    required String adId,
    required String userId,
  }) async {
    try {
      await _firestore.collection('cars').doc(adId).update({
        likedByUsersField: FieldValue.arrayRemove([userId]),
      });
    } on FirebaseException catch (e) {
      throw CarDatabaseException(e.message ?? 'Failed to remove favorite.');
    } catch (e) {
      throw CarDatabaseException('Failed to remove favorite: $e');
    }
  }

  /// Saves or updates an in-progress listing draft (`status == draft`).
  Future<String> saveCarDraft({
    String? draftId,
    required String sellerId,
    required Map<String, dynamic> carData,
    required List<String> imageUrls,
    required int lastStep,
  }) async {
    try {
      final data = <String, dynamic>{
        ...carData,
        sellerIdField: sellerId,
        statusField: statusDraft,
        'draftLastStep': lastStep,
        'updatedAt': FieldValue.serverTimestamp(),
        if (imageUrls.isNotEmpty) ...{
          'imageUrls': imageUrls,
          'imageUrl': imageUrls.first,
        },
      };

      if (draftId != null && draftId.isNotEmpty) {
        await _firestore
            .collection('cars')
            .doc(draftId)
            .set(data, SetOptions(merge: true));
        return draftId;
      }

      final doc = _firestore.collection('cars').doc();
      await doc.set({
        ...data,
        CarBidService.highestBidField: 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return doc.id;
    } on FirebaseException catch (e) {
      throw CarDatabaseException(e.message ?? 'Failed to save listing draft.');
    } catch (e) {
      throw CarDatabaseException('Failed to save listing draft: $e');
    }
  }

  /// Publishes a saved draft by promoting it to `pending` review.
  Future<void> publishDraftCarAd({
    required String draftId,
    required Map<String, dynamic> carData,
    required List<String> imageUrls,
  }) async {
    if (imageUrls.isEmpty) {
      throw CarDatabaseException(
        'Cannot publish car listing without image URLs.',
      );
    }

    try {
      await _firestore.collection('cars').doc(draftId).update({
        ...carData,
        statusField: statusPending,
        'imageUrls': imageUrls,
        'imageUrl': imageUrls.first,
        'draftLastStep': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw CarDatabaseException(
        e.message ?? 'Failed to publish listing draft.',
      );
    } catch (e) {
      throw CarDatabaseException('Failed to publish listing draft: $e');
    }
  }

  /// Saves a car ad to the `cars` collection with [imageUrls] and [createdAt].
  Future<String> publishCarAd(
    Map<String, dynamic> carData,
    List<String> imageUrls,
  ) async {
    if (imageUrls.isEmpty) {
      throw CarDatabaseException(
        'Cannot publish car listing without image URLs.',
      );
    }

    try {
      final doc = _firestore.collection('cars').doc();
      await doc.set({
        ...carData,
        statusField: statusPending,
        CarBidService.highestBidField: 0,
        'imageUrls': imageUrls,
        'imageUrl': imageUrls.first,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return doc.id;
    } on FirebaseException catch (e) {
      throw CarDatabaseException(e.message ?? 'Failed to publish car listing.');
    } catch (e) {
      throw CarDatabaseException('Failed to publish car listing: $e');
    }
  }

  /// Lists car ads awaiting admin approval (`status == pending`).
  Future<List<Map<String, dynamic>>> fetchPendingAds() async {
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot;
      try {
        snapshot = await _firestore
            .collection('cars')
            .where(statusField, isEqualTo: statusPending)
            .orderBy('createdAt', descending: true)
            .get();
      } on FirebaseException catch (e) {
        if (e.code != 'failed-precondition') rethrow;
        snapshot = await _firestore
            .collection('cars')
            .where(statusField, isEqualTo: statusPending)
            .get();
      }
      final ads = _mapsFromQuery(snapshot);
      ads.sort((a, b) {
        final aTime = a['createdAt'];
        final bTime = b['createdAt'];
        if (aTime is Timestamp && bTime is Timestamp) {
          return bTime.compareTo(aTime);
        }
        return 0;
      });
      return ads;
    } on FirebaseException catch (e) {
      debugPrint('Admin Fetch Error: $e');
      throw CarDatabaseException(e.message ?? 'Failed to fetch pending ads.');
    } catch (e) {
      debugPrint('Admin Fetch Error: $e');
      throw CarDatabaseException('Failed to fetch pending ads: $e');
    }
  }

  /// Updates the moderation [newStatus] of a car ad (e.g. `active`, `rejected`).
  Future<void> updateAdStatus({
    required String adId,
    required String newStatus,
    ActivityAuditContext? audit,
  }) async {
    try {
      await _firestore.collection('cars').doc(adId).update({
        statusField: newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (audit != null) {
        await _activityLog.logFromAudit(audit);
      }
    } on FirebaseException catch (e) {
      throw CarDatabaseException(e.message ?? 'Failed to update ad status.');
    } catch (e) {
      throw CarDatabaseException('Failed to update ad status: $e');
    }
  }

  /// Aggregate counts for the admin dashboard stats cards.
  Future<Map<String, int>> fetchAdminDashboardStats() async {
    try {
      final cars = _firestore.collection('cars');
      final users = _firestore.collection('users');

      final results = await Future.wait([
        _countQuery(cars.where(statusField, isEqualTo: statusPending)),
        _countQuery(cars.where(statusField, isEqualTo: statusActive)),
        _countQuery(users),
        _countQuery(
          users.where(accountTypeField, isEqualTo: accountTypeShowroom),
        ),
      ]);

      return {
        'pendingAds': results[0],
        'activeAds': results[1],
        'totalUsers': results[2],
        'totalShowrooms': results[3],
      };
    } on FirebaseException catch (e) {
      debugPrint('Admin Fetch Error: $e');
      throw CarDatabaseException(
        e.message ?? 'Failed to fetch admin dashboard stats.',
      );
    } catch (e) {
      debugPrint('Admin Fetch Error: $e');
      throw CarDatabaseException('Failed to fetch admin dashboard stats: $e');
    }
  }

  Future<int> _countQuery(Query<Map<String, dynamic>> query) async {
    final snapshot = await query.count().get();
    return snapshot.count ?? 0;
  }

  /// Updates an existing car ad, uploading [newImagesToUpload] to R2 and
  /// merging the resulting URLs with [existingImageUrls].
  Future<void> updateCarAd({
    required String adId,
    required Map<String, dynamic> updatedData,
    required List<String> existingImageUrls,
    required List<File> newImagesToUpload,
  }) async {
    try {
      final newUrls = await Future.wait(
        newImagesToUpload.asMap().entries.map((entry) async {
          final index = entry.key;
          final file = entry.value;
          final ext = _extensionFromPath(file.path);
          final uniqueName =
              '${DateTime.now().millisecondsSinceEpoch}_$index$ext';
          final bytes = await file.readAsBytes();
          if (bytes.isEmpty) {
            throw R2StorageException(
              'Image byte array is empty! Cannot upload 0 bytes.',
            );
          }
          return _r2.uploadImageBytes(bytes, fileName: uniqueName);
        }),
      );

      final imageUrls = [...existingImageUrls, ...newUrls];

      await _firestore.collection('cars').doc(adId).update({
        ...updatedData,
        'imageUrls': imageUrls,
        if (imageUrls.isNotEmpty) 'imageUrl': imageUrls.first,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on R2StorageException catch (e) {
      throw CarDatabaseException(e.message);
    } on FirebaseException catch (e) {
      throw CarDatabaseException(e.message ?? 'Failed to update car listing.');
    } catch (e) {
      throw CarDatabaseException('Failed to update car listing: $e');
    }
  }

  /// Deletes a car ad document and its associated R2 images when available.
  Future<void> deleteCarAd({
    required String adId,
    ActivityAuditContext? audit,
  }) async {
    try {
      final docRef = _firestore.collection('cars').doc(adId);
      final snapshot = await docRef.get();

      if (snapshot.exists) {
        final data = snapshot.data();
        final imageUrls = _urlListFromField(data?['imageUrls']);
        final damageUrls = _urlListFromField(data?['damageImageUrls']);

        if (imageUrls.isNotEmpty || damageUrls.isNotEmpty) {
          try {
            await _r2.deleteImageUrls([...imageUrls, ...damageUrls]);
          } on R2StorageException {
            // Best-effort cleanup — still remove the Firestore document.
          }
        }
      }

      await docRef.delete();
      if (audit != null) {
        await _activityLog.logFromAudit(audit);
      }
    } on FirebaseException catch (e) {
      throw CarDatabaseException(e.message ?? 'Failed to delete car listing.');
    } catch (e) {
      if (e is CarDatabaseException) rethrow;
      throw CarDatabaseException('Failed to delete car listing: $e');
    }
  }

  /// Finds active/sold listings matching detected brand, model, and optional year.
  Future<List<Car>> findListingsByDetection({
    required String brandId,
    String? modelKey,
    String? year,
    int limit = 12,
  }) async {
    try {
      final query = CarFirestoreFilterQuery(
        brandId: brandId,
        modelKey: modelKey,
        year: year,
      );
      final (cars, _) = await fetchFilteredActiveCarsPage(query, limit: limit);
      return cars;
    } on FirebaseException catch (e) {
      throw CarDatabaseException(
        e.message ?? 'Failed to search listings by detection.',
      );
    } catch (e) {
      throw CarDatabaseException('Failed to search listings by detection: $e');
    }
  }

  /// Server-side count for equality filters (price/mileage/year-range are client-only).
  Future<int> countFilteredActiveCars(CarFirestoreFilterQuery query) async {
    try {
      return await _countQuery(_filteredActiveCarsQuery(query));
    } on FirebaseException catch (e) {
      throw CarDatabaseException(
        e.message ?? 'Failed to count filtered active cars.',
      );
    } catch (e) {
      throw CarDatabaseException('Failed to count filtered active cars: $e');
    }
  }

  /// Paginated fetch of active listings with equality filters.
  /// Returns a tuple of the fetched cars and the last DocumentSnapshot for the next page.
  Future<(List<Car>, DocumentSnapshot?)> fetchFilteredActiveCarsPage(
    CarFirestoreFilterQuery query, {
    DocumentSnapshot? startAfter,
    int limit = 12,
  }) async {
    return FirebasePerformanceService.instance.traceAsync(
      'fetchFilteredActiveCarsPage',
      () async {
        try {
          Query<Map<String, dynamic>> q = _filteredActiveCarsQuery(
            query,
          ).orderBy('createdAt', descending: true).limit(limit);

          if (startAfter != null) {
            q = q.startAfterDocument(startAfter);
          }

          final snapshot = await q.get();
          final cars = _carsFromSnapshot(snapshot);

          final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
          return (cars, lastDoc);
        } on FirebaseException catch (e) {
          throw CarDatabaseException(
            e.message ?? 'Failed to fetch paginated active cars.',
          );
        } catch (e) {
          throw CarDatabaseException('Failed to fetch paginated active cars: $e');
        }
      },
      metrics: {'limit': limit},
    );
  }

  Query<Map<String, dynamic>> _filteredActiveCarsQuery(
    CarFirestoreFilterQuery query,
  ) {
    Query<Map<String, dynamic>> q = _firestore
        .collection('cars')
        .where(statusField, whereIn: publicFeedStatuses);

    if (query.brandId != null) {
      q = q.where('brandId', isEqualTo: query.brandId);
    }
    if (query.modelKey != null) {
      q = q.where('modelKey', isEqualTo: query.modelKey);
    }
    if (query.year != null) {
      q = q.where('year', isEqualTo: query.year);
    }
    if (query.conditionKey != null) {
      q = q.where('conditionKey', isEqualTo: query.conditionKey);
    }
    if (query.fuelKey != null) {
      q = q.where('fuelKey', isEqualTo: query.fuelKey);
    }
    if (query.colorKey != null) {
      q = q.where('colorKey', isEqualTo: query.colorKey);
    }
    if (query.transmissionKey != null) {
      q = q.where('transmissionKey', isEqualTo: query.transmissionKey);
    }
    if (query.plateCityKey != null) {
      q = q.where('plateCityKey', isEqualTo: query.plateCityKey);
    }
    if (query.plateTypeKey != null) {
      q = q.where('plateTypeKey', isEqualTo: query.plateTypeKey);
    }
    if (query.engineSizeKey != null) {
      q = q.where('engineSizeKey', isEqualTo: query.engineSizeKey);
    }
    if (query.cylindersKey != null) {
      q = q.where('cylindersKey', isEqualTo: query.cylindersKey);
    }
    if (query.importCountryKey != null) {
      q = q.where('importCountryKey', isEqualTo: query.importCountryKey);
    }
    if (query.seatMaterialKey != null) {
      q = q.where('seatMaterialKey', isEqualTo: query.seatMaterialKey);
    }

    return q;
  }

  static List<Car> _carsFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final cars = snapshot.docs
        .map((doc) => Car.fromMap(doc.id, doc.data()))
        .whereType<Car>()
        .toList();
    // ignore: avoid_print
    print(
      'Fetched ${snapshot.docs.length} docs, successfully parsed ${cars.length} cars',
    );
    cars.sort((a, b) => _compareByCreatedAtDesc(a.toMap(), b.toMap()));
    return cars;
  }

  Query<Map<String, dynamic>> _activeAdsQuery() {
    return _firestore
        .collection('cars')
        .where(statusField, whereIn: publicFeedStatuses)
        .orderBy('createdAt', descending: true);
  }

  static int _compareByCreatedAtDesc(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    final aTime = a['createdAt'];
    final bTime = b['createdAt'];
    if (aTime is Timestamp && bTime is Timestamp) {
      return bTime.compareTo(aTime);
    }
    return 0;
  }

  /// Recently added active/sold listings for the trending fallback row.
  Future<List<Map<String, dynamic>>> fetchTrendingCars({int limit = 10}) async {
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot;
      try {
        snapshot = await _activeAdsQuery().limit(limit).get();
      } on FirebaseException catch (e) {
        if (e.code != 'failed-precondition') rethrow;
        snapshot = await _firestore
            .collection('cars')
            .where(statusField, whereIn: publicFeedStatuses)
            .limit(limit)
            .get();
      }
      final ads = _mapsFromQuery(snapshot);
      ads.sort(_compareByCreatedAtDesc);
      if (ads.length <= limit) return ads;
      return ads.sublist(0, limit);
    } on FirebaseException catch (e) {
      throw CarDatabaseException(e.message ?? 'Failed to fetch trending cars.');
    } catch (e) {
      throw CarDatabaseException('Failed to fetch trending cars: $e');
    }
  }

  /// Matches saved brand/model interests — one equality query per interest.
  Future<List<Map<String, dynamic>>> fetchRecommendedCars(
    List<UserCarInterest> interests, {
    int limit = 10,
  }) async {
    if (interests.isEmpty) {
      return fetchTrendingCars(limit: limit);
    }

    try {
      final seenIds = <String>{};
      final results = <Map<String, dynamic>>[];

      for (final interest in interests) {
        if (results.length >= limit) break;

        final remaining = limit - results.length;
        final query = CarFirestoreFilterQuery(
          brandId: interest.brandId,
          modelKey: interest.modelKey,
        );
        final (cars, _) = await fetchFilteredActiveCarsPage(
          query,
          limit: remaining,
        );

        for (final car in cars) {
          final map = car.toMap();
          final id = map['id']?.toString();
          if (id == null || id.isEmpty || !seenIds.add(id)) continue;
          results.add(map);
          if (results.length >= limit) break;
        }
      }

      if (results.isEmpty) {
        return fetchTrendingCars(limit: limit);
      }
      return results;
    } on FirebaseException catch (e) {
      throw CarDatabaseException(
        e.message ?? 'Failed to fetch recommended cars.',
      );
    } catch (e) {
      throw CarDatabaseException('Failed to fetch recommended cars: $e');
    }
  }

  static List<Map<String, dynamic>> _mapsFromQuery(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }

  static List<String> _urlListFromField(dynamic value) {
    if (value is! List) return const [];
    return value.map((e) => e.toString()).where((u) => u.isNotEmpty).toList();
  }

  static String _extensionFromPath(String path) {
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex <= 0 || dotIndex >= path.length - 1) {
      return '.jpg';
    }
    return path.substring(dotIndex).toLowerCase();
  }
}
