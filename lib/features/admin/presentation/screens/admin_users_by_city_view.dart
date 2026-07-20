import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iq_motors/core/localization/iraq_location_l10n.dart';
import 'package:iq_motors/core/localization/l10n_extensions.dart';
import 'package:iq_motors/core/theme/app_theme.dart';
import 'package:iq_motors/features/admin/presentation/providers/admin_settings_provider.dart';
import 'package:iq_motors/features/storage/presentation/providers/storage_providers.dart';
import 'package:iq_motors/features/admin/data/services/admin_database_service.dart';
import 'package:iq_motors/features/admin/presentation/screens/admin_user_list_detail_screen.dart';
import 'package:iq_motors/shared/widgets/app_loading_indicator.dart';

/// User overview grid grouped by governorate for the admin users section.
class AdminUsersByCityView extends ConsumerStatefulWidget {
  const AdminUsersByCityView({
    super.key,
    required this.isMobile,
  });

  final bool isMobile;

  @override
  ConsumerState<AdminUsersByCityView> createState() =>
      _AdminUsersByCityViewState();
}

class _AdminUsersByCityViewState extends ConsumerState<AdminUsersByCityView> {
  late Future<Map<String, int>> _userCountsFuture;

  @override
  void initState() {
    super.initState();
    _userCountsFuture =
        ref.read(adminDatabaseServiceProvider).fetchUserCountByCity();
  }

  void _reload() {
    setState(() {
      _userCountsFuture =
          ref.read(adminDatabaseServiceProvider).fetchUserCountByCity();
    });
  }

  int _crossAxisCount(double width) {
    if (width >= 1500) return 4;
    if (width >= 1100) return 3;
    if (width >= 720) return 2;
    return 1;
  }

  void _openCityUsers(String city) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdminUserListDetailScreen(city: city),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _crossAxisCount(constraints.maxWidth);

        return FutureBuilder<Map<String, int>>(
          future: _userCountsFuture,
          builder: (context, snapshot) {
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting;
            final counts = snapshot.data ?? {};
            final cities = ref.watch(systemConfigProvider).value?.activeCities ??
                AdminDatabaseService.trackedCities;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.navUsers,
                  style: context.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.adminUsersByCitySubtitle,
                  style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 28),
                if (snapshot.hasError)
                  _ErrorBanner(
                    message: snapshot.error.toString(),
                    onRetry: _reload,
                  ),
                if (isLoading)
                  _UserCitySkeletonGrid(crossAxisCount: crossAxisCount)
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      mainAxisExtent: 160,
                    ),
                    itemCount: cities.length,
                    itemBuilder: (context, index) {
                      final city = cities[index];
                      final userCount = counts[city] ?? 0;

                      return _UserCityCard(
                        cityKey: city,
                        userCount: userCount,
                        userCountLabel: l10n.adminUserCountLabel,
                        onTap: () => _openCityUsers(city),
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

class _UserCityCard extends StatelessWidget {
  const _UserCityCard({
    required this.cityKey,
    required this.userCount,
    required this.userCountLabel,
    required this.onTap,
  });

  final String cityKey;
  final int userCount;
  final String userCountLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cityLabel =
        IraqLocationL10n.provinceLabel(context.l10n, cityKey);
    final scheme = context.colorScheme;

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
                top: 14,
                end: 14,
                child: Icon(
                  Icons.people_outline,
                  size: 52,
                  color: scheme.onSurface.withValues(alpha: 0.05),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    const Spacer(),
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.person_outline,
                            size: 22,
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$userCount',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              userCountLabel,
                              style: TextStyle(
                                fontSize: 13,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
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

class _UserCitySkeletonGrid extends StatelessWidget {
  const _UserCitySkeletonGrid({required this.crossAxisCount});

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
        mainAxisExtent: 160,
      ),
      itemCount: AdminDatabaseService.trackedCities.length,
      itemBuilder: (_, _) => Container(
        decoration: BoxDecoration(
          color: context.colorScheme.surfaceContainerLowest,
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
