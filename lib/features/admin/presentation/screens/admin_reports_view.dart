import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iq_motors/core/localization/iraq_location_l10n.dart';
import 'package:iq_motors/core/localization/l10n_extensions.dart';
import 'package:iq_motors/l10n/app_localizations.dart';
import 'package:iq_motors/features/admin/domain/models/admin_dashboard_analytics.dart';
import 'package:iq_motors/features/storage/presentation/providers/storage_providers.dart';

/// Analytics and revenue reports for the super-admin dashboard.
class AdminReportsView extends ConsumerStatefulWidget {
  const AdminReportsView({super.key, required this.isMobile});

  final bool isMobile;

  @override
  ConsumerState<AdminReportsView> createState() => _AdminReportsViewState();
}

class _AdminReportsViewState extends ConsumerState<AdminReportsView> {
  static const Color _textPrimary = Color(0xFF1D1D1F);
  static const Color _textSecondary = Color(0xFF86868B);
  static const Color _blue = Color(0xFF007AFF);
  static const Color _orange = Color(0xFFFF9500);

  late Future<AdminDashboardAnalytics> _analyticsFuture;

  @override
  void initState() {
    super.initState();
    _analyticsFuture =
        ref.read(adminDatabaseServiceProvider).fetchDashboardAnalytics();
  }

  void _reload() {
    setState(() {
      _analyticsFuture =
          ref.read(adminDatabaseServiceProvider).fetchDashboardAnalytics();
    });
  }

  String _formatIqd(int amount) {
    final formatted = amount.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
    return '$formatted IQD';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return FutureBuilder<AdminDashboardAnalytics>(
      future: _analyticsFuture,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.navReports,
              style: TextStyle(
                fontSize: widget.isMobile ? 24 : 28,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.adminReportsSubtitle,
              style: const TextStyle(fontSize: 14, color: _textSecondary),
            ),
            const SizedBox(height: 28),
            if (snapshot.hasError)
              _ErrorBanner(
                message: snapshot.error.toString(),
                retryLabel: l10n.adminRetry,
                onRetry: _reload,
              ),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (snapshot.hasData) ...[
              _buildChartsSection(snapshot.data!, l10n),
              const SizedBox(height: 20),
              _RevenueSummaryCard(
                totalRevenue: _formatIqd(snapshot.data!.totalRevenue),
                cardRevenue: _formatIqd(snapshot.data!.revenueCard),
                eWalletRevenue: _formatIqd(snapshot.data!.revenueEWallet),
                totalLabel: l10n.adminTotalRevenue,
                subtitleLabel: l10n.adminRevenueFromBoost,
                cardLabel: l10n.adminRevenueCard,
                eWalletLabel: l10n.adminRevenueEWallet,
                isMobile: widget.isMobile,
              ),
              const SizedBox(height: 20),
              _CityPerformanceTable(
                rows: snapshot.data!.cityPerformance,
                title: l10n.adminCityPerformance,
                cityLabel: l10n.adminCityColumn,
                totalLabel: l10n.adminTotalAdsColumn,
                approvedLabel: l10n.adminApprovedAdsColumn,
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildChartsSection(
    AdminDashboardAnalytics data,
    AppLocalizations l10n,
  ) {
    final usersChart = _ChartCard(
      title: l10n.adminDailyActiveUsers,
      subtitle: l10n.adminLast30Days,
      color: _blue,
      labels: data.dayLabels,
      values: data.dailyActiveUsers,
      isBarChart: false,
    );

    final adsChart = _ChartCard(
      title: l10n.adminDailyNewAds,
      subtitle: l10n.adminLast30Days,
      color: _orange,
      labels: data.dayLabels,
      values: data.dailyNewAds,
      isBarChart: true,
    );

    if (widget.isMobile) {
      return Column(
        children: [
          usersChart,
          const SizedBox(height: 16),
          adsChart,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: usersChart),
        const SizedBox(width: 16),
        Expanded(child: adsChart),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.labels,
    required this.values,
    required this.isBarChart,
  });

  final String title;
  final String subtitle;
  final Color color;
  final List<String> labels;
  final List<int> values;
  final bool isBarChart;

  static const Color _cardWhite = Color(0xFFFFFFFF);
  static const Color _textPrimary = Color(0xFF1D1D1F);
  static const Color _textSecondary = Color(0xFF86868B);

  double get _maxY {
    if (values.isEmpty) return 5;
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    return maxVal == 0 ? 5 : maxVal * 1.2;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 13, color: _textSecondary),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: isBarChart
                ? _buildBarChart()
                : _buildLineChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: _maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _maxY / 4,
          getDrawingHorizontalLine: (_) => FlLine(
            color: const Color(0xFFE5E5EA),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: const TextStyle(fontSize: 10, color: _textSecondary),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 5,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= labels.length) {
                  return const SizedBox.shrink();
                }
                if (index % 5 != 0 && index != labels.length - 1) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    labels[index],
                    style: const TextStyle(fontSize: 9, color: _textSecondary),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < values.length; i++)
                FlSpot(i.toDouble(), values[i].toDouble()),
            ],
            isCurved: true,
            color: color,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        minY: 0,
        maxY: _maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _maxY / 4,
          getDrawingHorizontalLine: (_) => FlLine(
            color: const Color(0xFFE5E5EA),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: const TextStyle(fontSize: 10, color: _textSecondary),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 5,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= labels.length) {
                  return const SizedBox.shrink();
                }
                if (index % 5 != 0 && index != labels.length - 1) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    labels[index],
                    style: const TextStyle(fontSize: 9, color: _textSecondary),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          for (var i = 0; i < values.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: values[i].toDouble(),
                  color: color,
                  width: 6,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _RevenueSummaryCard extends StatelessWidget {
  const _RevenueSummaryCard({
    required this.totalRevenue,
    required this.cardRevenue,
    required this.eWalletRevenue,
    required this.totalLabel,
    required this.subtitleLabel,
    required this.cardLabel,
    required this.eWalletLabel,
    required this.isMobile,
  });

  final String totalRevenue;
  final String cardRevenue;
  final String eWalletRevenue;
  final String totalLabel;
  final String subtitleLabel;
  final String cardLabel;
  final String eWalletLabel;
  final bool isMobile;

  static const Color _cardWhite = Color(0xFFFFFFFF);
  static const Color _textSecondary = Color(0xFF86868B);
  static const Color _blue = Color(0xFF007AFF);

  @override
  Widget build(BuildContext context) {
    final breakdown = isMobile
        ? Column(
            children: [
              _PaymentBreakdownTile(
                label: cardLabel,
                amount: cardRevenue,
                color: _blue,
                icon: Icons.credit_card_outlined,
              ),
              const SizedBox(height: 12),
              _PaymentBreakdownTile(
                label: eWalletLabel,
                amount: eWalletRevenue,
                color: const Color(0xFF34C759),
                icon: Icons.account_balance_wallet_outlined,
              ),
            ],
          )
        : Row(
            children: [
              Expanded(
                child: _PaymentBreakdownTile(
                  label: cardLabel,
                  amount: cardRevenue,
                  color: _blue,
                  icon: Icons.credit_card_outlined,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _PaymentBreakdownTile(
                  label: eWalletLabel,
                  amount: eWalletRevenue,
                  color: const Color(0xFF34C759),
                  icon: Icons.account_balance_wallet_outlined,
                ),
              ),
            ],
          );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            totalLabel,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            totalRevenue,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: _blue,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitleLabel,
            style: const TextStyle(fontSize: 13, color: _textSecondary),
          ),
          const SizedBox(height: 24),
          breakdown,
        ],
      ),
    );
  }
}

class _PaymentBreakdownTile extends StatelessWidget {
  const _PaymentBreakdownTile({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  final String label;
  final String amount;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  amount,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D1D1F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CityPerformanceTable extends StatelessWidget {
  const _CityPerformanceTable({
    required this.rows,
    required this.title,
    required this.cityLabel,
    required this.totalLabel,
    required this.approvedLabel,
  });

  final List<AdminCityPerformance> rows;
  final String title;
  final String cityLabel;
  final String totalLabel;
  final String approvedLabel;

  static const Color _cardWhite = Color(0xFFFFFFFF);
  static const Color _textPrimary = Color(0xFF1D1D1F);
  static const Color _textSecondary = Color(0xFF86868B);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  cityLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  totalLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  approvedLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 80),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _CityPerformanceRow(row: rows[i]),
          ],
        ],
      ),
    );
  }
}

class _CityPerformanceRow extends StatelessWidget {
  const _CityPerformanceRow({required this.row});

  final AdminCityPerformance row;

  static const Color _textPrimary = Color(0xFF1D1D1F);
  static const Color _green = Color(0xFF34C759);
  static const Color _orange = Color(0xFFFF9500);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pending = row.totalAds - row.approvedAds;
    final approvalFraction = row.approvalRate.clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              IraqLocationL10n.provinceLabel(l10n, row.city),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '${row.totalAds}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '${row.approvedAds}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _green,
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: approvalFraction,
                    minHeight: 6,
                    backgroundColor: _orange.withValues(alpha: 0.25),
                    color: _green,
                  ),
                ),
                if (pending > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '$pending',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 10,
                      color: _orange.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFFF3B30), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, color: Color(0xFF1D1D1F)),
            ),
          ),
          TextButton(onPressed: onRetry, child: Text(retryLabel)),
        ],
      ),
    );
  }
}
