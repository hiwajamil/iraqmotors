import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iq_motors/core/localization/l10n_extensions.dart';
import 'package:iq_motors/core/theme/app_theme.dart';
import 'package:iq_motors/features/marketplace/presentation/providers/user_interest_provider.dart';
import 'package:iq_motors/features/marketplace/presentation/screens/car_details_screen.dart';
import 'package:iq_motors/features/marketplace/presentation/widgets/home/home_theme.dart';
import 'package:iq_motors/features/marketplace/presentation/widgets/premium_car_card.dart';

/// Horizontal "Recommended for You" row — personalized or trending fallback.
class HomeRecommendedSection extends ConsumerWidget {
  const HomeRecommendedSection({
    super.key,
    required this.onWishlistTap,
  });

  final Future<void> Function(Map<String, dynamic> car) onWishlistTap;

  static const double _cardWidth = 272;
  static const double _listHeight = 315;
  /// Card width + separator for [ListView.itemExtent] (separator is outside
  /// extent when using separated — use fixed extent via itemBuilder SizedBox).
  static const double _itemExtent = _cardWidth + 14;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommended = ref.watch(recommendedCarsProvider);

    return recommended.when(
      skipLoadingOnReload: true,
      loading: () => const SliverToBoxAdapter(
        child: _RecommendedSkeleton(),
      ),
      error: (_, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
      data: (result) {
        if (result.cars.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        final l10n = context.l10n;
        final title = result.isPersonalized
            ? l10n.homeRecommendedForYou
            : l10n.homeTrendingCars;

        return SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              HomeSectionTitle(title: title),
              SizedBox(
                height: _listHeight,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemExtent: _itemExtent,
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 4),
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  itemCount: result.cars.length,
                  itemBuilder: (context, index) {
                    final car = result.cars[index];
                    final carId = car['id']?.toString();

                    return Padding(
                      padding: const EdgeInsetsDirectional.only(end: 14),
                      child: SizedBox(
                        width: _cardWidth,
                        child: PremiumCarCard(
                          key: ValueKey(carId ?? 'rec-$index'),
                          car: car,
                          compact: true,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    CarDetailsScreen(car: car),
                              ),
                            );
                          },
                          onWishlistTap: () => onWishlistTap(car),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}

class _RecommendedSkeleton extends StatelessWidget {
  const _RecommendedSkeleton();

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 12),
          child: Container(
            width: 180,
            height: 22,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        SizedBox(
          height: HomeRecommendedSection._listHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemExtent: HomeRecommendedSection._itemExtent,
            padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 4),
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            itemBuilder: (_, _) => Padding(
              padding: const EdgeInsetsDirectional.only(end: 14),
              child: Container(
                width: HomeRecommendedSection._cardWidth,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
