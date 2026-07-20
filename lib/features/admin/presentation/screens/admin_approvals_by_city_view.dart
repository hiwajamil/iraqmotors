import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iq_motors/core/localization/iraq_location_l10n.dart';
import 'package:iq_motors/core/localization/l10n_extensions.dart';
import 'package:iq_motors/core/theme/app_theme.dart';
import 'package:iq_motors/shared/data/iraq_locations.dart';
import 'package:iq_motors/shared/widgets/app_loading_indicator.dart';
import 'package:iq_motors/features/storage/presentation/providers/storage_providers.dart';

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
    final scheme = context.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _crossAxisCount(constraints.maxWidth);

        return FutureBuilder<Map<String, Map<String, int>>>(
          future: _cityStatsFuture,
          builder: (context, snapshot) {
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting;
            final cityStats = snapshot.data ?? {};
            final cities = IraqLocations.provinceOrder;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.navApprovals,
                  style: (widget.isMobile
                          ? context.textTheme.headlineSmall
                          : context.textTheme.headlineMedium)
                      ?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.adminApprovalsByCitySubtitle,
                  style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
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
                        cityKey: city,
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
    required this.cityKey,
    required this.stats,
    required this.approvedLabel,
    required this.pendingLabel,
    required this.expiredLabel,
    required this.onTap,
  });

  final String cityKey;
  final Map<String, int> stats;
  final String approvedLabel;
  final String pendingLabel;
  final String expiredLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final cityLabel = IraqLocationL10n.provinceLabel(l10n, cityKey);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Stack(
            children: [
              PositionedDirectional(
                top: 12,
                end: 12,
                child: Icon(
                  Icons.location_on_outlined,
                  size: 56,
                  color: scheme.onSurface.withValues(alpha: 0.05),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      cityLabel,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Divider(height: 1, color: scheme.outlineVariant),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _StatBadge(
                            label: approvedLabel,
                            count: stats['active'] ?? 0,
                            color: scheme.tertiary,
                            bg: scheme.tertiaryContainer,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatBadge(
                            label: pendingLabel,
                            count: stats['pending'] ?? 0,
                            color: scheme.secondary,
                            bg: scheme.secondaryContainer,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatBadge(
                            label: expiredLabel,
                            count: stats['expired'] ?? 0,
                            color: scheme.error,
                            bg: scheme.errorContainer,
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
    final scheme = context.colorScheme;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 196,
      ),
      itemCount: IraqLocations.provinceOrder.length,
      itemBuilder: (_, _) => Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: const AppLoadingIndicator.compact(),
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
    final scheme = context.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          TextButton(onPressed: onRetry, child: Text(l10n.adminRetry)),
        ],
      ),
    );
  }
}
