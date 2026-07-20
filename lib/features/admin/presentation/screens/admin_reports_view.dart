import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iq_motors/core/localization/iraq_location_l10n.dart';
import 'package:iq_motors/core/localization/l10n_extensions.dart';
import 'package:iq_motors/core/theme/app_theme.dart';
import 'package:iq_motors/l10n/app_localizations.dart';
import 'package:iq_motors/features/admin/domain/models/admin_dashboard_analytics.dart';
import 'package:iq_motors/features/admin/domain/models/analytics_date_range.dart';
import 'package:iq_motors/features/admin/presentation/providers/admin_settings_provider.dart';

/// Analytics and revenue reports for the super-admin dashboard.
class AdminReportsView extends ConsumerStatefulWidget {
  const AdminReportsView({super.key, required this.isMobile});

  final bool isMobile;

  @override
  ConsumerState<AdminReportsView> createState() => _AdminReportsViewState();
}

class _AdminReportsViewState extends ConsumerState<AdminReportsView> {
  late AnalyticsDateRange _dateRange;
  AdminDashboardAnalytics? _reportData;
  bool _isGenerating = false;
  Object? _loadError;
  int _loadToken = 0;
  bool _showVisitorTraffic = false;

  @override
  void initState() {
    super.initState();
    _dateRange = AnalyticsDateRange.last30Days();
  }

  void _generateReport() {
    final token = ++_loadToken;
    setState(() {
      _isGenerating = true;
      _loadError = null;
    });

    ref
        .read(analyticsServiceProvider)
        .fetchAnalytics(_dateRange)
        .then((data) {
      if (!mounted || token != _loadToken) return;
      setState(() {
        _reportData = data;
        _isGenerating = false;
      });
    }).catchError((Object error) {
      if (!mounted || token != _loadToken) return;
      setState(() {
        _loadError = error;
        _isGenerating = false;
      });
    });
  }

  void _clearReport() {
    _loadToken++;
    setState(() {
      _reportData = null;
      _loadError = null;
      _isGenerating = false;
    });
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _dateRange.start,
        end: _dateRange.end,
      ),
    );

    if (picked == null || !mounted) return;

    setState(() {
      _dateRange = AnalyticsDateRange(
        start: DateTime(
          picked.start.year,
          picked.start.month,
          picked.start.day,
        ),
        end: DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
        ),
      );
    });
    if (_reportData != null) {
      _clearReport();
    }
  }

  String _formatIqd(int amount) {
    final formatted = amount.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
    return '$formatted IQD';
  }

  String _formatCount(int value) {
    return value.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final showEmpty = _reportData == null && !_isGenerating;
    final showSkeleton = _isGenerating && _reportData == null;
    final showContent = _reportData != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.navReports,
          style: (widget.isMobile
                  ? context.textTheme.headlineSmall
                  : context.textTheme.headlineMedium)
              ?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
            height: 1.25,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.adminReportsSubtitle,
          style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        _buildControls(l10n),
        if (_loadError != null) ...[
          const SizedBox(height: 16),
          _ErrorBanner(
            message: _loadError.toString(),
            retryLabel: l10n.adminRetry,
            onRetry: _generateReport,
          ),
        ],
        if (showEmpty) ...[
          const SizedBox(height: 48),
          _ReportsEmptyState(hint: l10n.adminReportsEmptyHint),
        ] else if (showSkeleton) ...[
          const SizedBox(height: 20),
          _buildReportSkeleton(l10n),
        ] else if (showContent) ...[
          const SizedBox(height: 20),
          _buildReportContent(_reportData!, l10n, isLoading: _isGenerating),
        ],
      ],
    );
  }

  void _exportCsv() {
    if (_reportData == null) return;
    final data = _reportData!;
    final totalNewAds = data.dailyNewAds.fold<int>(0, (a, b) => a + b);
    final sb = StringBuffer();
    sb.writeln('IQ Motors Analytics Report');
    sb.writeln('Date Range: ${_dateRange.formatChip()}');
    sb.writeln('Total Revenue (IQD),${data.totalRevenue}');
    sb.writeln('Card Revenue (IQD),${data.revenueCard}');
    sb.writeln('E-Wallet Revenue (IQD),${data.revenueEWallet}');
    sb.writeln('Total New Ads,$totalNewAds');
    sb.writeln();
    sb.writeln('Governorate,Total Ads,Approved Ads');
    for (final city in data.cityPerformance) {
      sb.writeln('${city.city},${city.totalAds},${city.approvedAds}');
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exported CSV Data'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: SelectableText(
              sb.toString(),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: sb.toString()));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('CSV copied to clipboard')),
              );
            },
            child: const Text('Copy to Clipboard'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(AppLocalizations l10n) {
    if (widget.isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DateRangeBar(
            label: l10n.adminDateRangeLabel,
            rangeText: _dateRange.formatChip(),
            onTap: _pickDateRange,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _GenerateReportButton(
                  label: l10n.adminGenerateReport,
                  isLoading: _isGenerating,
                  onPressed: _generateReport,
                ),
              ),
              if (_reportData != null) ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _exportCsv,
                  icon: const Icon(Icons.download_outlined, size: 18),
                  label: const Text('Export CSV'),
                ),
              ],
            ],
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _DateRangeBar(
            label: l10n.adminDateRangeLabel,
            rangeText: _dateRange.formatChip(),
            onTap: _pickDateRange,
          ),
        ),
        const SizedBox(width: 16),
        _GenerateReportButton(
          label: l10n.adminGenerateReport,
          isLoading: _isGenerating,
          onPressed: _generateReport,
        ),
        if (_reportData != null) ...[
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: _exportCsv,
            icon: const Icon(Icons.download_outlined, size: 18),
            label: const Text('Export CSV'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReportSkeleton(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSummaryRow(l10n, isLoading: true),
        const SizedBox(height: 20),
        _buildChartsSection(l10n, isLoading: true),
        const SizedBox(height: 20),
        _CardLoadingShell(
          isLoading: true,
          child: _RevenueBreakdownCard(
            totalRevenue: '—',
            cardRevenue: '—',
            eWalletRevenue: '—',
            totalLabel: l10n.adminTotalRevenue,
            subtitleLabel: l10n.adminRevenueFromBoost,
            cardLabel: l10n.adminRevenueCard,
            eWalletLabel: l10n.adminRevenueEWallet,
            isMobile: widget.isMobile,
          ),
        ),
        const SizedBox(height: 20),
        _CardLoadingShell(
          isLoading: true,
          child: _CityPerformanceTable(
            rows: const [],
            title: l10n.adminCityPerformance,
            cityLabel: l10n.adminCityColumn,
            totalLabel: l10n.adminTotalAdsColumn,
            approvedLabel: l10n.adminApprovedAdsColumn,
            visitorLabel: l10n.adminVisitorTraffic,
            adsMetricLabel: l10n.adminCityMetricAds,
            visitorsMetricLabel: l10n.adminCityMetricVisitors,
            showVisitorTraffic: _showVisitorTraffic,
            onMetricChanged: (_) {},
          ),
        ),
      ],
    );
  }

  Widget _buildReportContent(
    AdminDashboardAnalytics data,
    AppLocalizations l10n, {
    required bool isLoading,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSummaryRow(l10n, data: data, isLoading: isLoading),
        const SizedBox(height: 20),
        _buildChartsSection(l10n, data: data, isLoading: isLoading),
        const SizedBox(height: 20),
        _CardLoadingShell(
          isLoading: isLoading,
          child: _RevenueBreakdownCard(
            totalRevenue: _formatIqd(data.totalRevenue),
            cardRevenue: _formatIqd(data.revenueCard),
            eWalletRevenue: _formatIqd(data.revenueEWallet),
            totalLabel: l10n.adminTotalRevenue,
            subtitleLabel: l10n.adminRevenueFromBoost,
            cardLabel: l10n.adminRevenueCard,
            eWalletLabel: l10n.adminRevenueEWallet,
            isMobile: widget.isMobile,
          ),
        ),
        const SizedBox(height: 20),
        _CardLoadingShell(
          isLoading: isLoading,
          child: _CityPerformanceTable(
            rows: data.cityPerformance,
            title: l10n.adminCityPerformance,
            cityLabel: l10n.adminCityColumn,
            totalLabel: l10n.adminTotalAdsColumn,
            approvedLabel: l10n.adminApprovedAdsColumn,
            visitorLabel: l10n.adminVisitorTraffic,
            adsMetricLabel: l10n.adminCityMetricAds,
            visitorsMetricLabel: l10n.adminCityMetricVisitors,
            showVisitorTraffic: _showVisitorTraffic,
            onMetricChanged: (showVisitors) {
              setState(() => _showVisitorTraffic = showVisitors);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(
    AppLocalizations l10n, {
    AdminDashboardAnalytics? data,
    required bool isLoading,
  }) {
    final scheme = context.colorScheme;
    final revenueCard = _CardLoadingShell(
      isLoading: isLoading,
      child: _SummaryStatCard(
        label: l10n.adminTotalRevenue,
        value: data != null ? _formatIqd(data.totalRevenue) : '—',
        subtitle: l10n.adminRevenueFromBoost,
        accentColor: scheme.primary,
        icon: Icons.payments_outlined,
      ),
    );
    final activeUsersCard = _CardLoadingShell(
      isLoading: isLoading,
      child: _SummaryStatCard(
        label: l10n.adminTodaysActiveUsers,
        value: data != null ? _formatCount(data.todaysActiveUsers) : '—',
        subtitle: l10n.adminDailyActiveUsers,
        accentColor: scheme.tertiary,
        icon: Icons.people_outline_rounded,
      ),
    );
    final downloadsCard = _CardLoadingShell(
      isLoading: isLoading,
      child: _SummaryStatCard(
        label: l10n.adminTotalAppDownloads,
        value: data != null ? _formatCount(data.totalAppDownloads) : '—',
        subtitle: l10n.adminLast30Days,
        accentColor: scheme.secondary,
        icon: Icons.download_rounded,
      ),
    );

    if (widget.isMobile) {
      return Column(
        children: [
          revenueCard,
          const SizedBox(height: 12),
          activeUsersCard,
          const SizedBox(height: 12),
          downloadsCard,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: revenueCard),
        const SizedBox(width: 16),
        Expanded(child: activeUsersCard),
        const SizedBox(width: 16),
        Expanded(child: downloadsCard),
      ],
    );
  }

  Widget _buildChartsSection(
    AppLocalizations l10n, {
    AdminDashboardAnalytics? data,
    required bool isLoading,
  }) {
    final scheme = context.colorScheme;
    final rangeSubtitle = _dateRange.formatChip();
    final labels = data?.dayLabels ?? const <String>[];
    final dauValues = data?.dailyActiveUsers ?? const <int>[];
    final adsValues = data?.dailyNewAds ?? const <int>[];

    final usersChart = _CardLoadingShell(
      isLoading: isLoading,
      child: _ChartCard(
        title: l10n.adminDailyActiveUsers,
        subtitle: rangeSubtitle,
        color: scheme.primary,
        labels: labels,
        values: dauValues,
        isBarChart: false,
      ),
    );

    final adsChart = _CardLoadingShell(
      isLoading: isLoading,
      child: _ChartCard(
        title: l10n.adminDailyNewAds,
        subtitle: rangeSubtitle,
        color: scheme.secondary,
        labels: labels,
        values: adsValues,
        isBarChart: true,
      ),
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

class _GenerateReportButton extends StatelessWidget {
  const _GenerateReportButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return FilledButton.icon(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      ),
      icon: isLoading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: scheme.onPrimary,
              ),
            )
          : const Icon(Icons.insights_rounded, size: 20),
      label: Text(label),
    );
  }
}

class _ReportsEmptyState extends StatelessWidget {
  const _ReportsEmptyState({required this.hint});

  final String hint;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 56),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.analytics_outlined,
              size: 36,
              color: scheme.primary.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardLoadingShell extends StatelessWidget {
  const _CardLoadingShell({
    required this.isLoading,
    required this.child,
  });

  final bool isLoading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Stack(
      children: [
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isLoading ? 0.45 : 1,
          child: child,
        ),
        if (isLoading)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: ColoredBox(
                color: scheme.surface.withValues(alpha: 0.55),
                child: const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DateRangeBar extends StatelessWidget {
  const _DateRangeBar({
    required this.label,
    required this.rangeText,
    required this.onTap,
  });

  final String label;
  final String rangeText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  size: 20,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      rangeText,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryStatCard extends StatelessWidget {
  const _SummaryStatCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.accentColor,
    required this.icon,
  });

  final String label;
  final String value;
  final String subtitle;
  final Color accentColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: accentColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: accentColor,
              letterSpacing: -0.6,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
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

  double get _maxY {
    if (values.isEmpty) return 5;
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    return maxVal == 0 ? 5 : maxVal * 1.2;
  }

  double get _labelInterval {
    if (values.length <= 7) return 1;
    if (values.length <= 14) return 2;
    return (values.length / 6).ceilToDouble();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: isBarChart
                ? _buildBarChart(scheme.outlineVariant, scheme.onSurfaceVariant)
                : _buildLineChart(scheme.outlineVariant, scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(Color gridColor, Color labelColor) {
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: _maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _maxY / 4,
          getDrawingHorizontalLine: (_) => FlLine(
            color: gridColor,
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
                style: TextStyle(fontSize: 10, color: labelColor),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: _labelInterval,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= labels.length) {
                  return const SizedBox.shrink();
                }
                if (index % _labelInterval != 0 && index != labels.length - 1) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    labels[index],
                    style: TextStyle(fontSize: 9, color: labelColor),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < values.length; i++)
                FlSpot(i.toDouble(), values[i].toDouble()),
            ],
            isCurved: true,
            curveSmoothness: 0.35,
            preventCurveOverShooting: true,
            color: color,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withValues(alpha: 0.28),
                  color.withValues(alpha: 0.04),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(Color gridColor, Color labelColor) {
    return BarChart(
      BarChartData(
        minY: 0,
        maxY: _maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _maxY / 4,
          getDrawingHorizontalLine: (_) => FlLine(
            color: gridColor,
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
                style: TextStyle(fontSize: 10, color: labelColor),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: _labelInterval,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= labels.length) {
                  return const SizedBox.shrink();
                }
                if (index % _labelInterval != 0 && index != labels.length - 1) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    labels[index],
                    style: TextStyle(fontSize: 9, color: labelColor),
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
                  width: values.length > 20 ? 5 : 8,
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

class _RevenueBreakdownCard extends StatelessWidget {
  const _RevenueBreakdownCard({
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

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final breakdown = isMobile
        ? Column(
            children: [
              _PaymentBreakdownTile(
                label: cardLabel,
                amount: cardRevenue,
                color: scheme.primary,
                icon: Icons.credit_card_outlined,
              ),
              const SizedBox(height: 12),
              _PaymentBreakdownTile(
                label: eWalletLabel,
                amount: eWalletRevenue,
                color: scheme.tertiary,
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
                  color: scheme.primary,
                  icon: Icons.credit_card_outlined,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _PaymentBreakdownTile(
                  label: eWalletLabel,
                  amount: eWalletRevenue,
                  color: scheme.tertiary,
                  icon: Icons.account_balance_wallet_outlined,
                ),
              ),
            ],
          );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            totalLabel,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            totalRevenue,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: scheme.primary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitleLabel,
            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
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
    final scheme = context.colorScheme;
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
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
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
    required this.visitorLabel,
    required this.adsMetricLabel,
    required this.visitorsMetricLabel,
    required this.showVisitorTraffic,
    required this.onMetricChanged,
  });

  final List<AdminCityPerformance> rows;
  final String title;
  final String cityLabel;
  final String totalLabel;
  final String approvedLabel;
  final String visitorLabel;
  final String adsMetricLabel;
  final String visitorsMetricLabel;
  final bool showVisitorTraffic;
  final ValueChanged<bool> onMetricChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final maxVisitors = rows.isEmpty
        ? 1
        : rows.map((r) => r.visitorCount).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              _MetricToggle(
                adsLabel: adsMetricLabel,
                visitorsLabel: visitorsMetricLabel,
                showVisitors: showVisitorTraffic,
                onChanged: onMetricChanged,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  cityLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (!showVisitorTraffic) ...[
                Expanded(
                  child: Text(
                    totalLabel,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    approvedLabel,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 80),
              ] else ...[
                Expanded(
                  flex: 2,
                  child: Text(
                    visitorLabel,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _CityPerformanceRow(
              row: rows[i],
              showVisitorTraffic: showVisitorTraffic,
              maxVisitors: maxVisitors,
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricToggle extends StatelessWidget {
  const _MetricToggle({
    required this.adsLabel,
    required this.visitorsLabel,
    required this.showVisitors,
    required this.onChanged,
  });

  final String adsLabel;
  final String visitorsLabel;
  final bool showVisitors;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<bool>(
      segments: [
        ButtonSegment(value: false, label: Text(adsLabel)),
        ButtonSegment(value: true, label: Text(visitorsLabel)),
      ],
      selected: {showVisitors},
      onSelectionChanged: (next) {
        if (next.isEmpty) return;
        onChanged(next.first);
      },
      showSelectedIcon: false,
      style: const ButtonStyle(
        visualDensity: VisualDensity.standard,
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
    );
  }
}

class _CityPerformanceRow extends StatelessWidget {
  const _CityPerformanceRow({
    required this.row,
    required this.showVisitorTraffic,
    required this.maxVisitors,
  });

  final AdminCityPerformance row;
  final bool showVisitorTraffic;
  final int maxVisitors;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final pending = row.totalAds - row.approvedAds;
    final approvalFraction = row.approvalRate.clamp(0.0, 1.0);
    final visitorFraction =
        maxVisitors == 0 ? 0.0 : row.visitorCount / maxVisitors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              IraqLocationL10n.provinceLabel(l10n, row.city),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
          ),
          if (!showVisitorTraffic) ...[
            Expanded(
              child: Text(
                '${row.totalAds}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
            ),
            Expanded(
              child: Text(
                '${row.approvedAds}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: scheme.tertiary,
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
                      backgroundColor: scheme.secondary.withValues(alpha: 0.25),
                      color: scheme.tertiary,
                    ),
                  ),
                  if (pending > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '$pending',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: 10,
                        color: scheme.secondary.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ] else
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    row.visitorCount.toString().replaceAllMapped(
                          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
                          (match) => '${match[1]},',
                        ),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: visitorFraction.clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: scheme.primary.withValues(alpha: 0.12),
                      color: scheme.primary,
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
    final scheme = context.colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: scheme.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 13, color: scheme.onErrorContainer),
            ),
          ),
          TextButton(onPressed: onRetry, child: Text(retryLabel)),
        ],
      ),
    );
  }
}
