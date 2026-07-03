import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iq_motors/core/localization/iraq_location_l10n.dart';
import 'package:iq_motors/core/localization/l10n_extensions.dart';
import 'package:iq_motors/features/admin/presentation/providers/admin_settings_provider.dart';
import 'package:iq_motors/features/storage/presentation/providers/storage_providers.dart';
import 'package:iq_motors/features/admin/data/services/admin_database_service.dart';
import 'package:iq_motors/features/admin/presentation/screens/admin_user_list_detail_screen.dart';

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
  static const Color _textPrimary = Color(0xFF1D1D1F);
  static const Color _textSecondary = Color(0xFF86868B);

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
                  style: TextStyle(
                    fontSize: widget.isMobile ? 24 : 28,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.adminUsersByCitySubtitle,
                  style: const TextStyle(fontSize: 14, color: _textSecondary),
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

  static const Color _cardWhite = Color(0xFFFFFFFF);
  static const Color _textPrimary = Color(0xFF1D1D1F);
  static const Color _textSecondary = Color(0xFF86868B);
  static const Color _accentBlue = Color(0xFF007AFF);

  @override
  Widget build(BuildContext context) {
    final cityLabel =
        IraqLocationL10n.provinceLabel(context.l10n, cityKey);

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
                top: 14,
                end: 14,
                child: Icon(
                  Icons.people_outline,
                  size: 52,
                  color: _textPrimary.withValues(alpha: 0.05),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cityLabel,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
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
                            color: const Color(0xFFE8F2FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.person_outline,
                            size: 22,
                            color: _accentBlue,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$userCount',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: _textPrimary,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              userCountLabel,
                              style: const TextStyle(
                                fontSize: 13,
                                color: _textSecondary,
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
