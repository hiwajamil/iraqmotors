import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n_extensions.dart';
import '../../providers/admin_settings_provider.dart';
import '../../providers/storage_providers.dart';
import '../../services/admin_database_service.dart';

/// City overview grid for the admin approvals sidebar section.
class AdminApprovalsByCityView extends ConsumerStatefulWidget {
  const AdminApprovalsByCityView({
    super.key,
    required this.isMobile,
    required this.horizontalPadding,
  });

  final bool isMobile;
  final double horizontalPadding;

  @override
  ConsumerState<AdminApprovalsByCityView> createState() =>
      _AdminApprovalsByCityViewState();
}

class _AdminApprovalsByCityViewState
    extends ConsumerState<AdminApprovalsByCityView> {
  static const Color _textPrimary = Color(0xFF1D1D1F);
  static const Color _textSecondary = Color(0xFF86868B);

  late Future<Map<String, Map<String, int>>> _cityStatsFuture;

  @override
  void initState() {
    super.initState();
    _cityStatsFuture =
        ref.read(adminDatabaseServiceProvider).fetchAdStatsByCity();
  }

  void _reload() {
    setState(() {
      _cityStatsFuture =
          ref.read(adminDatabaseServiceProvider).fetchAdStatsByCity();
    });
  }

  int _crossAxisCount(double width) {
    if (width >= 1200) return 3;
    if (width >= 720) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _crossAxisCount(constraints.maxWidth);

        return FutureBuilder<Map<String, Map<String, int>>>(
          future: _cityStatsFuture,
          builder: (context, snapshot) {
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting;
            final cityStats = snapshot.data ?? {};
            final cities = ref.watch(systemConfigProvider).value?.activeCities ??
                AdminDatabaseService.trackedCities;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.navApprovals,
                  style: TextStyle(
                    fontSize: widget.isMobile ? 24 : 28,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.adminApprovalsByCitySubtitle,
                  style: const TextStyle(fontSize: 14, color: _textSecondary),
                ),
                const SizedBox(height: 28),
                if (snapshot.hasError)
                  _ErrorBanner(
                    message: snapshot.error.toString(),
                    onRetry: _reload,
                  ),
                if (isLoading)
                  _CityStatsSkeletonGrid(crossAxisCount: crossAxisCount)
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      mainAxisExtent: 196,
                    ),
            itemCount: cities.length,
            itemBuilder: (context, index) {
              final city = cities[index];
                      final stats = cityStats[city] ??
                          const {'active': 0, 'pending': 0, 'expired': 0};

                      return _CityStatsCard(
                        cityName: city,
                        stats: stats,
                        approvedLabel: l10n.adminStatApproved,
                        pendingLabel: l10n.adminStatPendingReview,
                        expiredLabel: l10n.adminStatExpired,
                        onTap: () {
                          if (kDebugMode) {
                            debugPrint('Admin city tapped: $city');
                          }
                        },
                      );
                    },
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _CityStatsCard extends StatelessWidget {
  const _CityStatsCard({
    required this.cityName,
    required this.stats,
    required this.approvedLabel,
    required this.pendingLabel,
    required this.expiredLabel,
    required this.onTap,
  });

  final String cityName;
  final Map<String, int> stats;
  final String approvedLabel;
  final String pendingLabel;
  final String expiredLabel;
  final VoidCallback onTap;

  static const Color _cardWhite = Color(0xFFFFFFFF);
  static const Color _textPrimary = Color(0xFF1D1D1F);
  static const Color _divider = Color(0xFFE5E5EA);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: _cardWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              PositionedDirectional(
                top: 12,
                end: 12,
                child: Icon(
                  Icons.location_on_outlined,
                  size: 56,
                  color: _textPrimary.withValues(alpha: 0.05),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      cityName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Divider(height: 1, color: _divider),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _StatBadge(
                            label: approvedLabel,
                            count: stats['active'] ?? 0,
                            color: const Color(0xFF34C759),
                            bg: const Color(0xFFE8F8ED),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatBadge(
                            label: pendingLabel,
                            count: stats['pending'] ?? 0,
                            color: const Color(0xFFFF9500),
                            bg: const Color(0xFFFFF4E6),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatBadge(
                            label: expiredLabel,
                            count: stats['expired'] ?? 0,
                            color: const Color(0xFFFF3B30),
                            bg: const Color(0xFFFFEBEA),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.label,
    required this.count,
    required this.color,
    required this.bg,
  });

  final String label;
  final int count;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(height: 6),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.85),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _CityStatsSkeletonGrid extends StatelessWidget {
  const _CityStatsSkeletonGrid({required this.crossAxisCount});

  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 196,
      ),
      itemCount: AdminDatabaseService.trackedCities.length,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

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
          TextButton(onPressed: onRetry, child: Text(l10n.adminRetry)),
        ],
      ),
    );
  }
}
