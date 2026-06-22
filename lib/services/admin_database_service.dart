import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/activity_actions.dart';
import '../data/add_car_option_keys.dart';
import '../data/iraq_locations.dart';
import '../models/activity_log.dart';
import '../models/admin_dashboard_analytics.dart';
import '../models/admin_system_config.dart';
import 'activity_log_service.dart';
import 'car_database_service.dart';

class AdminDatabaseException implements Exception {
  AdminDatabaseException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Admin-only Firestore queries (city stats, moderation overview, etc.).
class AdminDatabaseService {
  AdminDatabaseService({
    FirebaseFirestore? firestore,
    ActivityLogService? activityLog,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _activityLog = activityLog ?? ActivityLogService();

  final FirebaseFirestore _firestore;
  final ActivityLogService _activityLog;

  static const String provinceField = 'province';
  static const String cityField = 'city';
  static const String accountTypeField = 'accountType';
  static const String userTypeField = 'userType';
  static const String showroomUserType = 'showroom';

  /// Major governorates shown on admin city grids (defaults; see [fetchSystemConfig]).
  static const List<String> trackedCities =
      AdminSystemConfig.defaultTrackedCities;

  static const Map<String, int> _emptyCityStats = {
    'active': 0,
    'pending': 0,
    'expired': 0,
  };

  /// Returns per-city ad counts keyed by governorate name.
  ///
  /// Each city map contains `active`, `pending`, and `expired` totals.
  Future<Map<String, Map<String, int>>> fetchAdStatsByCity() async {
    try {
      final cities = IraqLocations.provinceOrder;
      // Single collection read; group by province and status locally.
      final snapshot = await _firestore.collection('cars').get();

      final result = {
        for (final city in cities)
          city: Map<String, int>.from(_emptyCityStats),
      };

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final province = data[provinceField]?.toString();
        if (province == null || !result.containsKey(province)) continue;

        final stats = result[province]!;
        switch (data[CarDatabaseService.statusField]?.toString()) {
          case CarDatabaseService.statusActive:
            stats['active'] = stats['active']! + 1;
          case CarDatabaseService.statusPending:
            stats['pending'] = stats['pending']! + 1;
          case CarDatabaseService.statusExpired:
            stats['expired'] = stats['expired']! + 1;
        }
      }

      return result;
    } on FirebaseException catch (e) {
      throw AdminDatabaseException(
        e.message ?? 'Failed to fetch ad stats by city.',
      );
    } catch (e) {
      throw AdminDatabaseException('Failed to fetch ad stats by city: $e');
    }
  }

  /// Returns user counts grouped by governorate (`city` field on user docs).
  Future<Map<String, int>> fetchUserCountByCity() async {
    try {
      final cities = (await fetchSystemConfig()).activeCities;
      final snapshot = await _firestore.collection('users').get();

      final result = {for (final city in cities) city: 0};

      for (final doc in snapshot.docs) {
        final city = doc.data()[cityField]?.toString();
        if (city == null || !result.containsKey(city)) continue;
        result[city] = result[city]! + 1;
      }

      return result;
    } on FirebaseException catch (e) {
      throw AdminDatabaseException(
        e.message ?? 'Failed to fetch user counts by city.',
      );
    } catch (e) {
      throw AdminDatabaseException('Failed to fetch user counts by city: $e');
    }
  }

  /// Lists users registered in [city] with their active ad counts.
  Future<List<Map<String, dynamic>>> fetchUsersByCity(String city) async {
    try {
      final usersSnap = await _firestore
          .collection('users')
          .where(cityField, isEqualTo: city)
          .get();

      final sellerIds = usersSnap.docs.map((d) => d.id).toList();
      final activeAdCounts = await _activeAdCountsForSellers(sellerIds);

      return usersSnap.docs.map((doc) {
        final data = doc.data();
        final uid = doc.id;
        return {
          'id': uid,
          'fullName': _resolveUserName(data),
          'phoneNumber': _resolvePhone(data),
          'userType': _resolveUserType(data),
          'activeAdCount': activeAdCounts[uid] ?? 0,
        };
      }).toList();
    } on FirebaseException catch (e) {
      throw AdminDatabaseException(
        e.message ?? 'Failed to fetch users for $city.',
      );
    } catch (e) {
      throw AdminDatabaseException('Failed to fetch users for $city: $e');
    }
  }

  Future<Map<String, int>> _activeAdCountsForSellers(
    List<String> sellerIds,
  ) async {
    if (sellerIds.isEmpty) return const {};

    final sellerSet = sellerIds.toSet();
    final snapshot = await _firestore
        .collection('cars')
        .where(CarDatabaseService.statusField,
            isEqualTo: CarDatabaseService.statusActive)
        .get();

    final counts = <String, int>{};
    for (final doc in snapshot.docs) {
      final sellerId =
          doc.data()[CarDatabaseService.sellerIdField]?.toString();
      if (sellerId == null || !sellerSet.contains(sellerId)) continue;
      counts[sellerId] = (counts[sellerId] ?? 0) + 1;
    }
    return counts;
  }

  static String _resolveUserName(Map<String, dynamic> data) {
    for (final key in ['displayName', 'fullName', 'showroomName']) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return '—';
  }

  static String _resolvePhone(Map<String, dynamic> data) {
    return data['phoneNumber']?.toString() ??
        data['phone']?.toString() ??
        '—';
  }

  static String _resolveUserType(Map<String, dynamic> data) {
    final accountType = data[accountTypeField]?.toString().toLowerCase();
    if (accountType == 'showroom') return 'showroom';

    final userType = data['userType']?.toString().toLowerCase();
    if (userType == 'showroom') return 'showroom';
    return 'individual';
  }

  static bool _isShowroom(Map<String, dynamic> data) {
    final accountType = data[accountTypeField]?.toString().toLowerCase();
    if (accountType == showroomUserType) return true;

    final userType = data[userTypeField]?.toString().toLowerCase();
    return userType == showroomUserType;
  }

  /// Returns showroom counts grouped by governorate (`city` field).
  Future<Map<String, int>> fetchShowroomCountByCity() async {
    try {
      final cities = (await fetchSystemConfig()).activeCities;
      final snapshot = await _firestore.collection('users').get();

      final result = {for (final city in cities) city: 0};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (!_isShowroom(data)) continue;

        final city = data[cityField]?.toString();
        if (city == null || !result.containsKey(city)) continue;
        result[city] = result[city]! + 1;
      }

      return result;
    } on FirebaseException catch (e) {
      throw AdminDatabaseException(
        e.message ?? 'Failed to fetch showroom counts by city.',
      );
    } catch (e) {
      throw AdminDatabaseException(
        'Failed to fetch showroom counts by city: $e',
      );
    }
  }

  /// Lists showrooms in [city] with their total ad counts.
  Future<List<Map<String, dynamic>>> fetchShowroomsByCity(String city) async {
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot;
      try {
        snapshot = await _firestore
            .collection('users')
            .where(accountTypeField, isEqualTo: showroomUserType)
            .where(cityField, isEqualTo: city)
            .get();
      } on FirebaseException catch (e) {
        if (e.code != 'failed-precondition') rethrow;
        snapshot = await _firestore
            .collection('users')
            .where(cityField, isEqualTo: city)
            .get();
      }

      final docs = snapshot.docs.where((doc) => _isShowroom(doc.data()));
      final sellerIds = docs.map((d) => d.id).toList();
      final totalAdCounts = await _totalAdCountsForSellers(sellerIds);

      return docs.map((doc) {
        final data = doc.data();
        final uid = doc.id;
        return {
          'id': uid,
          'showroomName': _resolveShowroomName(data),
          'phoneNumber': _resolvePhone(data),
          'address': _resolveAddress(data),
          'adCount': totalAdCounts[uid] ?? 0,
        };
      }).toList();
    } on FirebaseException catch (e) {
      throw AdminDatabaseException(
        e.message ?? 'Failed to fetch showrooms for $city.',
      );
    } catch (e) {
      throw AdminDatabaseException('Failed to fetch showrooms for $city: $e');
    }
  }

  static String _resolveShowroomName(Map<String, dynamic> data) {
    for (final key in ['showroomName', 'displayName', 'fullName']) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return '—';
  }

  static String _resolveAddress(Map<String, dynamic> data) {
    final address = data['address']?.toString().trim();
    if (address != null && address.isNotEmpty) return address;
    return data[cityField]?.toString() ?? '—';
  }

  Future<Map<String, int>> _totalAdCountsForSellers(
    List<String> sellerIds,
  ) async {
    if (sellerIds.isEmpty) return const {};

    final sellerSet = sellerIds.toSet();
    final snapshot = await _firestore.collection('cars').get();

    final counts = <String, int>{};
    for (final doc in snapshot.docs) {
      final sellerId =
          doc.data()[CarDatabaseService.sellerIdField]?.toString();
      if (sellerId == null || !sellerSet.contains(sellerId)) continue;
      counts[sellerId] = (counts[sellerId] ?? 0) + 1;
    }
    return counts;
  }

  static const int _analyticsDays = 30;

  static const String _configCollection = 'system_config';
  static const String _configDocId = 'platform';

  /// Aggregates revenue, activity, and city performance for admin reports.
  Future<AdminDashboardAnalytics> fetchDashboardAnalytics() async {
    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: _analyticsDays - 1));

      final dayLabels = List.generate(_analyticsDays, (i) {
        final day = start.add(Duration(days: i));
        return '${day.month}/${day.day}';
      });

      final usersSnap = await _firestore.collection('users').get();
      final carsSnap = await _firestore.collection('cars').get();
      final config = await fetchSystemConfig();
      final packagePrices = config.packagePrices;

      final dailyUsers = List<int>.filled(_analyticsDays, 0);
      final dailyAds = List<int>.filled(_analyticsDays, 0);

      for (final doc in usersSnap.docs) {
        final createdAt = _timestampToDate(doc.data()['createdAt']);
        if (createdAt == null) continue;
        _incrementDayBucket(dailyUsers, start, createdAt);
      }

      var totalRevenue = 0;
      var revenueCard = 0;
      var revenueEWallet = 0;

      final cityTotals = {
        for (final city in config.activeCities) city: 0,
      };
      final cityApproved = {
        for (final city in config.activeCities) city: 0,
      };

      for (final doc in carsSnap.docs) {
        final data = doc.data();
        final createdAt = _timestampToDate(data['createdAt']);
        if (createdAt != null) {
          _incrementDayBucket(dailyAds, start, createdAt);
        }

        final packageKey = data['packageKey']?.toString();
        final price = packagePrices[packageKey] ??
            AdminSystemConfig.defaultPackagePrices[packageKey] ??
            0;
        if (price > 0) {
          totalRevenue += price;
          final paymentKey = data['paymentMethodKey']?.toString();
          if (_isEWalletPayment(paymentKey)) {
            revenueEWallet += price;
          } else if (_isCardPayment(paymentKey)) {
            revenueCard += price;
          } else {
            revenueCard += price;
          }
        }

        final province = data[provinceField]?.toString();
        if (province != null && cityTotals.containsKey(province)) {
          cityTotals[province] = cityTotals[province]! + 1;
          if (data[CarDatabaseService.statusField]?.toString() ==
              CarDatabaseService.statusActive) {
            cityApproved[province] = cityApproved[province]! + 1;
          }
        }
      }

      final cityPerformance = config.activeCities
          .map(
            (city) => AdminCityPerformance(
              city: city,
              totalAds: cityTotals[city] ?? 0,
              approvedAds: cityApproved[city] ?? 0,
            ),
          )
          .toList()
        ..sort((a, b) => b.totalAds.compareTo(a.totalAds));

      return AdminDashboardAnalytics(
        dayLabels: dayLabels,
        dailyActiveUsers: dailyUsers,
        dailyNewAds: dailyAds,
        totalRevenue: totalRevenue,
        revenueCard: revenueCard,
        revenueEWallet: revenueEWallet,
        cityPerformance: cityPerformance,
      );
    } on FirebaseException catch (e) {
      throw AdminDatabaseException(
        e.message ?? 'Failed to fetch dashboard analytics.',
      );
    } catch (e) {
      throw AdminDatabaseException('Failed to fetch dashboard analytics: $e');
    }
  }

  static DateTime? _timestampToDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  static void _incrementDayBucket(
    List<int> bucket,
    DateTime start,
    DateTime date,
  ) {
    final normalized = DateTime(date.year, date.month, date.day);
    final index = normalized.difference(start).inDays;
    if (index >= 0 && index < bucket.length) {
      bucket[index]++;
    }
  }

  static bool _isCardPayment(String? key) {
    return key == AddCarOptionKeys.paymentDebitCard ||
        key == AddCarOptionKeys.paymentFib;
  }

  static bool _isEWalletPayment(String? key) {
    return key == AddCarOptionKeys.paymentEWallet;
  }

  /// Reads platform settings from Firestore (`system_config/platform`).
  Future<AdminSystemConfig> fetchSystemConfig() async {
    try {
      final doc = await _firestore
          .collection(_configCollection)
          .doc(_configDocId)
          .get();
      return AdminSystemConfig.fromFirestore(doc.data());
    } on FirebaseException catch (e) {
      throw AdminDatabaseException(
        e.message ?? 'Failed to fetch system config.',
      );
    } catch (e) {
      throw AdminDatabaseException('Failed to fetch system config: $e');
    }
  }

  /// Persists [config] to Firestore with a server timestamp.
  Future<void> saveSystemConfig(
    AdminSystemConfig config, {
    ActivityAuditContext? audit,
  }) async {
    try {
      await _firestore.collection(_configCollection).doc(_configDocId).set(
        {
          ...config.toFirestore(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      if (audit != null) {
        await _activityLog.logFromAudit(audit);
      }
    } on FirebaseException catch (e) {
      throw AdminDatabaseException(
        e.message ?? 'Failed to save system config.',
      );
    } catch (e) {
      throw AdminDatabaseException('Failed to save system config: $e');
    }
  }

  /// Updates a single package price and records the change in the audit log.
  Future<void> updatePackagePrice({
    required String packageKey,
    required int priceIqd,
    required String adminId,
    required String details,
    String? adminDisplayName,
  }) async {
    try {
      final config = await fetchSystemConfig();
      final updatedPrices = Map<String, int>.from(config.packagePrices)
        ..[packageKey] = priceIqd;
      final updated = config.copyWith(packagePrices: updatedPrices);

      await _firestore.collection(_configCollection).doc(_configDocId).set(
        {
          ...updated.toFirestore(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await _activityLog.logActivity(
        adminId: adminId,
        action: ActivityActions.updatedPackagePrice,
        details: details,
        adminDisplayName: adminDisplayName,
      );
    } on FirebaseException catch (e) {
      throw AdminDatabaseException(
        e.message ?? 'Failed to update package price.',
      );
    } catch (e) {
      if (e is AdminDatabaseException) rethrow;
      throw AdminDatabaseException('Failed to update package price: $e');
    }
  }
}
