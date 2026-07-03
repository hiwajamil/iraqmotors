import 'package:iq_motors/features/admin/domain/models/analytics_date_range.dart';

/// Aggregated analytics payload for the admin reports dashboard.
class AdminDashboardAnalytics {
  const AdminDashboardAnalytics({
    required this.range,
    required this.dayLabels,
    required this.dailyActiveUsers,
    required this.dailyNewAds,
    required this.todaysActiveUsers,
    required this.totalAppDownloads,
    required this.totalRevenue,
    required this.revenueCard,
    required this.revenueEWallet,
    required this.cityPerformance,
  });

  final AnalyticsDateRange range;
  final List<String> dayLabels;
  final List<int> dailyActiveUsers;
  final List<int> dailyNewAds;
  final int todaysActiveUsers;
  final int totalAppDownloads;
  final int totalRevenue;
  final int revenueCard;
  final int revenueEWallet;
  final List<AdminCityPerformance> cityPerformance;
}

class AdminCityPerformance {
  const AdminCityPerformance({
    required this.city,
    required this.totalAds,
    required this.approvedAds,
    required this.visitorCount,
  });

  final String city;
  final int totalAds;
  final int approvedAds;
  final int visitorCount;

  double get approvalRate =>
      totalAds == 0 ? 0 : approvedAds / totalAds;
}
