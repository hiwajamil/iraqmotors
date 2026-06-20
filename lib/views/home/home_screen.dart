import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n_extensions.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/filter_providers.dart';
import '../../services/car_database_service.dart';
import '../../widgets/brand_search_sheet.dart';
import '../../widgets/home/home_feed_empty_state.dart';
import '../../widgets/home/home_footer.dart';
import '../../widgets/home/home_glass_nav_bar.dart';
import '../../widgets/home/home_hero_section.dart';
import '../../widgets/home/home_theme.dart';
import '../../widgets/premium_car_card.dart';
import '../auth/auth_screen.dart';
import '../filters/advanced_filter_screen.dart';
import '../listings/car_details_screen.dart';

/// Explore / home — glass nav, centered hero, filters, listing grid.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool _immersiveNav = true;
  late final AnimationController _heroController;
  late final Animation<double> _heroFade;
  late final Animation<Offset> _heroSlide;

  @override
  void initState() {
    super.initState();
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _heroFade = CurvedAnimation(parent: _heroController, curve: Curves.easeOut);
    _heroSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _heroController, curve: Curves.easeOut));
    _heroController.forward();
  }

  List<Widget> _listingSlivers({
    required BuildContext context,
    required AsyncValue<List<Map<String, dynamic>>> activeAds,
    required Set<String> favoriteIds,
    required double width,
    required bool isWide,
    required double hPadding,
    required int crossAxisCount,
  }) {
    final l10n = context.l10n;

    return activeAds.when(
      loading: () => [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 72),
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          ),
        ),
      ],
      error: (_, __) => [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 72),
            child: Center(
              child: Text(
                l10n.homeFeedLoadError,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: HomeScreenColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ],
      data: (cars) {
        if (cars.isEmpty) {
          return [
            SliverToBoxAdapter(
              child: HomeFeedEmptyState(message: l10n.homeFeedEmpty),
            ),
          ];
        }

        return [
          SliverPadding(
            padding: EdgeInsetsDirectional.fromSTEB(
              isWide ? hPadding : 10,
              0,
              isWide ? hPadding : 10,
              0,
            ),
            sliver: SliverGrid(
              gridDelegate: _gridDelegate(width, crossAxisCount),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final car = cars[index];
                  final carId = car['id']?.toString();

                  return PremiumCarCard(
                    key: ValueKey(carId ?? 'car-$index'),
                    car: car,
                    compact: !isWide,
                    animationDelay: Duration(
                      milliseconds: 100 * (index + 1),
                    ),
                    isWishlisted:
                        carId != null && favoriteIds.contains(carId),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => CarDetailsScreen(
                            car: car,
                          ),
                        ),
                      );
                    },
                    onWishlistTap: () => _onWishlistTap(car),
                  );
                },
                childCount: cars.length,
                findChildIndexCallback: (Key key) {
                  if (key is! ValueKey<String>) return null;
                  final id = key.value;
                  final index = cars.indexWhere(
                    (car) => (car['id']?.toString() ?? '') == id,
                  );
                  return index >= 0 ? index : null;
                },
              ),
            ),
          ),
        ];
      },
    );
  }

  @override
  void dispose() {
    _heroController.dispose();
    super.dispose();
  }

  Future<void> _openAdvancedFilter(
    BuildContext context,
    int resultCount,
  ) async {
    final filterState = ref.read(filterStateProvider);
    final result = await AdvancedFilterScreen.show(
      context,
      initialFilters: filterState.filters,
      initialBrand: filterState.brand,
      resultCount: resultCount,
    );
    if (result == null || !mounted) return;
    ref.read(filterStateProvider.notifier).applyAdvancedFilterResult(result);
  }

  double _horizontalPadding(double width) => width * 0.08;

  int _gridCrossAxisCount(double width, double padding) {
    if (width < 768) return 2;
    final available = width - (padding * 2);
    final count = (available / 350).floor();
    return count.clamp(2, 4);
  }

  SliverGridDelegate _gridDelegate(double width, int crossAxisCount) {
    if (width < 768) {
      return const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.68,
      );
    }
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 30,
      crossAxisSpacing: 30,
      mainAxisExtent: 530,
    );
  }

  Future<void> _onWishlistTap(Map<String, dynamic> car) async {
    final l10n = context.l10n;

    try {
      final isNowFavorited =
          await ref.read(favoritesProvider.notifier).toggle(car);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isNowFavorited ? l10n.saveToWishlist : l10n.removeFromWishlist,
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } on FavoritesAuthRequired {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const AuthScreen()),
      );
    } on CarDatabaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFFF3B30),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final navLinks = [l10n.navAllModels, l10n.navTuning, l10n.navShowrooms];
    final favoriteIds = ref.watch(favoritesProvider);
    final filterState = ref.watch(filterStateProvider);
    final filterNotifier = ref.read(filterStateProvider.notifier);
    final homeCars = ref.watch(homeCarsProvider);
    final cars = homeCars.value ?? const <Map<String, dynamic>>[];

    return Scaffold(
      backgroundColor: HomeScreenColors.background,
      extendBodyBehindAppBar: true,
      appBar: HomeGlassNavBar(
        height: HomeGlassNavBar.heightOf(context),
        isWide: MediaQuery.sizeOf(context).width >= 768,
        immersive: _immersiveNav,
        navLinks: navLinks,
        horizontalPadding: _horizontalPadding(MediaQuery.sizeOf(context).width),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          final isWide = MediaQuery.sizeOf(context).width >= 768;
          if (isWide) return false;

          final screenHeight = MediaQuery.sizeOf(context).height;
          final heroHeight =
              (screenHeight * 0.5).clamp(450.0, screenHeight * 0.55);
          final offset = notification.metrics.pixels;
          final immersive =
              offset < heroHeight - HomeGlassNavBar.heightOf(context);
          if (immersive != _immersiveNav) {
            setState(() => _immersiveNav = immersive);
          }
          return false;
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isWide = width >= 768;
            final hPadding = _horizontalPadding(width);
            final crossAxisCount = _gridCrossAxisCount(width, hPadding);

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _heroFade,
                    child: SlideTransition(
                      position: _heroSlide,
                      child: HomeHeroSection(
                        isWide: isWide,
                        selectedBrand: filterState.brand,
                        filterValues: filterState.filters,
                        showAdvancedFilter: filterState.showAdvancedFilter,
                        onAdvancedSearchToggle: () =>
                            _openAdvancedFilter(context, cars.length),
                        onBrandSelected: filterNotifier.setBrand,
                        onFilterChanged: filterNotifier.setFilters,
                        onClearFilters: filterNotifier.clearFilters,
                        onShowResults: () {},
                        resultCount: cars.length,
                        onViewAllBrands: () async {
                          final brand =
                              await BrandSearchSheet.show(context);
                          if (brand != null) {
                            filterNotifier.setBrand(brand);
                          }
                        },
                      ),
                    ),
                  ),
                ),
                ..._listingSlivers(
                  context: context,
                  activeAds: homeCars,
                  favoriteIds: favoriteIds,
                  width: width,
                  isWide: isWide,
                  hPadding: hPadding,
                  crossAxisCount: crossAxisCount,
                ),
                const SliverToBoxAdapter(
                  child: HomeFooter(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
