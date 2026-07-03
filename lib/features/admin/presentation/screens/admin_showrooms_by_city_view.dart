import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iq_motors/core/localization/iraq_location_l10n.dart';
import 'package:iq_motors/core/localization/l10n_extensions.dart';
import 'package:iq_motors/features/admin/presentation/providers/admin_settings_provider.dart';
import 'package:iq_motors/features/storage/presentation/providers/storage_providers.dart';
import 'package:iq_motors/features/admin/data/services/admin_database_service.dart';
import 'package:iq_motors/features/admin/presentation/screens/admin_showroom_list_detail_screen.dart';

/// Showroom overview grid grouped by governorate for the admin showrooms section.
class AdminShowroomsByCityView extends ConsumerStatefulWidget {
  const AdminShowroomsByCityView({
    super.key,
    required this.isMobile,
  });

  final bool isMobile;

  @override
  ConsumerState<AdminShowroomsByCityView> createState() =>
      _AdminShowroomsByCityViewState();
}

class _AdminShowroomsByCityViewState
    extends ConsumerState<AdminShowroomsByCityView> {
  static const Color _textPrimary = Color(0xFF1D1D1F);
  static const Color _textSecondary = Color(0xFF86868B);

  late Future<Map<String, int>> _showroomCountsFuture;

  @override
  void initState() {
    super.initState();
    _showroomCountsFuture =
        ref.read(adminDatabaseServiceProvider).fetchShowroomCountByCity();
  }

  void _reload() {
    setState(() {
      _showroomCountsFuture =
          ref.read(adminDatabaseServiceProvider).fetchShowroomCountByCity();
    });
  }

  int _crossAxisCount(double width) {
    if (width >= 1500) return 4;
    if (width >= 1100) return 3;
    if (width >= 720) return 2;
    return 1;
  }

  void _openCityShowrooms(String city) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdminShowroomListDetailScreen(city: city),
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
          future: _showroomCountsFuture,
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
                  l10n.navShowrooms,
                  style: TextStyle(
                    fontSize: widget.isMobile ? 24 : 28,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.adminShowroomsByCitySubtitle,
                  style: const TextStyle(fontSize: 14, color: _textSecondary),
                ),
                const SizedBox(height: 28),
                if (snapshot.hasError)
                  _ErrorBanner(
                    message: snapshot.error.toString(),
                    onRetry: _reload,
                  ),
                if (isLoading)
                  _ShowroomCitySkeletonGrid(crossAxisCount: crossAxisCount)
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
                      final showroomCount = counts[city] ?? 0;

                      return _ShowroomCityCard(
                        cityKey: city,
                        showroomCount: showroomCount,
                        showroomCountLabel: l10n.adminShowroomCountLabel,
                        onTap: () => _openCityShowrooms(city),
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

class _ShowroomCityCard extends StatelessWidget {
  const _ShowroomCityCard({
    required this.cityKey,
    required this.showroomCount,
    required this.showroomCountLabel,
    required this.onTap,
  });

  final String cityKey;
  final int showroomCount;
  final String showroomCountLabel;
  final VoidCallback onTap;

  static const Color _cardWhite = Color(0xFFFFFFFF);
  static const Color _textPrimary = Color(0xFF1D1D1F);
  static const Color _textSecondary = Color(0xFF86868B);
  static const Color _accentPurple = Color(0xFFAF52DE);

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
                  Icons.storefront_outlined,
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
                            color: const Color(0xFFF3EBFF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.store_outlined,
                            size: 22,
                            color: _accentPurple,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$showroomCount',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: _textPrimary,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              showroomCountLabel,
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

class _ShowroomCitySkeletonGrid extends StatelessWidget {
  const _ShowroomCitySkeletonGrid({required this.crossAxisCount});

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
