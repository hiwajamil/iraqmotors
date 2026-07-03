import 'package:iq_motors/features/admin/data/services/admin_database_service.dart';
import 'package:iq_motors/features/admin/data/services/google_analytics_remote_service.dart';
import 'package:iq_motors/features/admin/domain/models/admin_dashboard_analytics.dart';
import 'package:iq_motors/features/admin/domain/models/analytics_date_range.dart';

/// Merges Firestore revenue/ad metrics with GA metrics from Cloud Functions.
class AnalyticsService {
  const AnalyticsService({
    required AdminDatabaseService adminDatabase,
    required GoogleAnalyticsRemoteService gaRemote,
  })  : _adminDatabase = adminDatabase,
        _gaRemote = gaRemote;

  final AdminDatabaseService _adminDatabase;
  final GoogleAnalyticsRemoteService _gaRemote;

  Future<AdminDashboardAnalytics> fetchAnalytics(
    AnalyticsDateRange range,
  ) async {
    final firestoreFuture = _adminDatabase.fetchDashboardAnalytics(range);
    final gaFuture = fetchGaAnalyticsSafely(_gaRemote, range);

    final results = await Future.wait([firestoreFuture, gaFuture]);
    final firestore = results[0] as AdminDashboardAnalytics;
    final ga = results[1] as GaAdminAnalyticsPayload;

    final mergedCities = firestore.cityPerformance
        .map(
          (row) => AdminCityPerformance(
            city: row.city,
            totalAds: row.totalAds,
            approvedAds: row.approvedAds,
            visitorCount: ga.cityVisitors[row.city] ?? 0,
          ),
        )
        .toList();

    if (ga.cityVisitors.isNotEmpty) {
      mergedCities.sort((a, b) {
        final visitorCompare = b.visitorCount.compareTo(a.visitorCount);
        return visitorCompare != 0
            ? visitorCompare
            : b.totalAds.compareTo(a.totalAds);
      });
    }

    return AdminDashboardAnalytics(
      range: firestore.range,
      dayLabels: firestore.dayLabels,
      dailyActiveUsers: ga.dailyActiveUsers.isNotEmpty
          ? ga.dailyActiveUsers
          : firestore.dailyActiveUsers,
      dailyNewAds: firestore.dailyNewAds,
      todaysActiveUsers: ga.todaysActiveUsers,
      totalAppDownloads: ga.totalAppDownloads,
      totalRevenue: firestore.totalRevenue,
      revenueCard: firestore.revenueCard,
      revenueEWallet: firestore.revenueEWallet,
      cityPerformance: mergedCities,
    );
  }
}
