/// Aggregated analytics payload for the admin reports dashboard.
class AdminDashboardAnalytics {
  const AdminDashboardAnalytics({
    required this.dayLabels,
    required this.dailyActiveUsers,
    required this.dailyNewAds,
    required this.totalRevenue,
    required this.revenueCard,
    required this.revenueEWallet,
    required this.cityPerformance,
  });

  /// Short labels for the last 30 days (oldest → newest).
  final List<String> dayLabels;
  final List<int> dailyActiveUsers;
  final List<int> dailyNewAds;
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
  });

  final String city;
  final int totalAds;
  final int approvedAds;

  double get approvalRate =>
      totalAds == 0 ? 0 : approvedAds / totalAds;
}
