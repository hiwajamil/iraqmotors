import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iq_motors/core/localization/l10n_extensions.dart';
import 'package:iq_motors/features/marketplace/presentation/providers/user_interest_provider.dart';
import 'package:iq_motors/features/marketplace/presentation/screens/car_details_screen.dart';
import 'package:iq_motors/features/marketplace/presentation/widgets/home/home_theme.dart';
import 'package:iq_motors/features/marketplace/presentation/widgets/premium_car_card.dart';

/// Horizontal "Recommended for You" row — personalized or trending fallback.
class HomeRecommendedSection extends ConsumerWidget {
  const HomeRecommendedSection({
    super.key,
    required this.favoriteIds,
    required this.onWishlistTap,
  });

  final Set<String> favoriteIds;
  final Future<void> Function(Map<String, dynamic> car) onWishlistTap;

  static const double _cardWidth = 272;
  static const double _listHeight = 315;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommended = ref.watch(recommendedCarsProvider);

    return recommended.when(
      loading: () => const SliverToBoxAdapter(
        child: _RecommendedSkeleton(),
      ),
      error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
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
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 4),
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  itemCount: result.cars.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    final car = result.cars[index];
                    final carId = car['id']?.toString();

                    return SizedBox(
                      width: _cardWidth,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 24,
                              offset: Offset(0, 8),
                            ),
                            BoxShadow(
                              color: Color(0x0A000000),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: PremiumCarCard(
                            key: ValueKey(carId ?? 'rec-$index'),
                            car: car,
                            compact: true,
                            isWishlisted:
                                carId != null && favoriteIds.contains(carId),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => CarDetailsScreen(car: car),
                                ),
                              );
                            },
                            onWishlistTap: () => onWishlistTap(car),
                          ),
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
              color: const Color(0xFFE8E8ED),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        SizedBox(
          height: HomeRecommendedSection._listHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 4),
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (_, __) => Container(
              width: HomeRecommendedSection._cardWidth,
              decoration: BoxDecoration(
                color: const Color(0xFFE8E8ED),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
