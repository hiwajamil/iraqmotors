import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iq_motors/core/localization/l10n_extensions.dart';
import 'package:iq_motors/features/marketplace/presentation/providers/favorites_provider.dart';
import 'package:iq_motors/features/marketplace/presentation/providers/filter_providers.dart';
import 'package:iq_motors/features/marketplace/data/services/car_database_service.dart';
import 'package:iq_motors/features/marketplace/presentation/widgets/brand_search_sheet.dart';
import 'package:iq_motors/features/marketplace/presentation/widgets/home/home_feed_empty_state.dart';
import 'package:iq_motors/features/marketplace/presentation/widgets/home/home_footer.dart';
import 'package:iq_motors/features/marketplace/presentation/widgets/home/home_glass_nav_bar.dart';
import 'package:iq_motors/features/marketplace/presentation/widgets/home/home_hero_section.dart';
import 'package:iq_motors/features/marketplace/presentation/providers/user_interest_provider.dart';
import 'package:iq_motors/features/marketplace/presentation/widgets/home/home_pagination.dart';
import 'package:iq_motors/features/marketplace/presentation/widgets/home/home_recommended_section.dart';
import 'package:iq_motors/features/marketplace/presentation/widgets/home/home_theme.dart';
import 'package:iq_motors/features/marketplace/presentation/widgets/premium_car_card.dart';
import 'package:iq_motors/features/auth/presentation/screens/auth_screen.dart';
import 'package:iq_motors/features/marketplace/presentation/screens/advanced_filter_screen.dart';
import 'package:iq_motors/features/marketplace/presentation/screens/car_details_screen.dart';

/// Explore / home — glass nav, centered hero, filters, listing grid.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  static const int _rowsPerPageDesktop = 6;
  static const int _rowsPerPageMobileWeb = 4;

  final ValueNotifier<bool> _immersiveNav = ValueNotifier(true);
  final GlobalKey _listingsAnchorKey = GlobalKey();
  int _currentPage = 1;
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

  int _rowsPerPage(double width) {
    if (kIsWeb && width < 768) return _rowsPerPageMobileWeb;
    return _rowsPerPageDesktop;
  }

  int _pageSize(int crossAxisCount, double width) =>
      crossAxisCount * _rowsPerPage(width);

  int? _pendingPageSync;

  void _schedulePageSync(int page) {
    if (page == _currentPage || page == _pendingPageSync) return;
    _pendingPageSync = page;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final nextPage = _pendingPageSync;
      _pendingPageSync = null;
      if (nextPage != null && nextPage != _currentPage) {
        setState(() => _currentPage = nextPage);
      }
    });
  }

  void _selectPage(int page) {
    if (page == _currentPage) return;
    setState(() => _currentPage = page);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _listingsAnchorKey.currentContext;
      if (context != null && mounted) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
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

        final pageSize = _pageSize(crossAxisCount, width);
        final totalPages = (cars.length / pageSize).ceil().clamp(1, 999999);
        final currentPage = _currentPage.clamp(1, totalPages);
        _schedulePageSync(currentPage);

        final startIndex = (currentPage - 1) * pageSize;
        final endIndex = (startIndex + pageSize).clamp(0, cars.length);
        final pageCars = cars.sublist(startIndex, endIndex);

        return [
          SliverToBoxAdapter(
            key: _listingsAnchorKey,
            child: const SizedBox.shrink(),
          ),
          if (!isWide)
            SliverToBoxAdapter(
              child: HomeSectionTitle(
                title: l10n.homeAvailableListings,
                trailing: Text(
                  '${cars.length}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: HomeScreenColors.textSecondary,
                  ),
                ),
              ),
            ),
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
                  final car = pageCars[index];
                  final carId = car['id']?.toString();

                  return PremiumCarCard(
                    key: ValueKey(carId ?? 'car-$index'),
                    car: car,
                    compact: !isWide,
                    animationDelay: kIsWeb && isWide
                        ? Duration(milliseconds: 100 * (index + 1))
                        : Duration.zero,
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
                childCount: pageCars.length,
                findChildIndexCallback: (Key key) {
                  if (key is! ValueKey<String>) return null;
                  final id = key.value;
                  final index = pageCars.indexWhere(
                    (car) => (car['id']?.toString() ?? '') == id,
                  );
                  return index >= 0 ? index : null;
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: HomePagination(
              currentPage: currentPage,
              totalPages: totalPages,
              onPageSelected: _selectPage,
            ),
          ),
        ];
      },
    );
  }

  @override
  void dispose() {
    _immersiveNav.dispose();
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
    _recordFilterInterest(result.brand?.id, result.filters.modelKey);
  }

  void _recordFilterInterest(String? brandId, String? modelKey) {
    if (brandId == null || brandId.isEmpty) return;
    ref.read(userInterestRevisionProvider.notifier).record(
          brandId: brandId,
          modelKey: modelKey,
        );
  }

  double _horizontalPadding(double width) =>
      width >= 768 ? width * 0.08 : 16;

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
        childAspectRatio: 0.76,
      );
    }
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 30,
      crossAxisSpacing: 30,
      mainAxisExtent: 455,
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
    ref.listen(filterStateProvider, (_, __) {
      if (_currentPage != 1 && mounted) {
        setState(() => _currentPage = 1);
      }
    });
    final filterNotifier = ref.read(filterStateProvider.notifier);
    final homeCars = ref.watch(homeCarsProvider);
    final cars = homeCars.value ?? const <Map<String, dynamic>>[];

    return Scaffold(
      backgroundColor: HomeScreenColors.background,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(HomeGlassNavBar.heightOf(context)),
        child: ValueListenableBuilder<bool>(
          valueListenable: _immersiveNav,
          builder: (context, immersiveNav, _) {
            return HomeGlassNavBar(
              height: HomeGlassNavBar.heightOf(context),
              isWide: MediaQuery.sizeOf(context).width >= 768,
              immersive: immersiveNav,
              navLinks: navLinks,
              horizontalPadding:
                  _horizontalPadding(MediaQuery.sizeOf(context).width),
            );
          },
        ),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          final isWide = MediaQuery.sizeOf(context).width >= 768;
          if (isWide) return false;

          final screenHeight = MediaQuery.sizeOf(context).height;
          final heroHeight = HomeHeroSection.mobileHeroHeight(screenHeight);
          final offset = notification.metrics.pixels;
          final immersive =
              offset < heroHeight - HomeGlassNavBar.heightOf(context);
          if (immersive != _immersiveNav.value) {
            _immersiveNav.value = immersive;
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
                        onBrandSelected: (brand) {
                          filterNotifier.setBrand(brand);
                          if (brand != null) {
                            _recordFilterInterest(
                              brand.id,
                              ref.read(filterStateProvider).filters.modelKey,
                            );
                          }
                        },
                        onFilterChanged: (filters) {
                          filterNotifier.setFilters(filters);
                          final brand = ref.read(filterStateProvider).brand;
                          if (brand != null && filters.modelKey != null) {
                            _recordFilterInterest(brand.id, filters.modelKey);
                          }
                        },
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
                HomeRecommendedSection(
                  favoriteIds: favoriteIds,
                  onWishlistTap: _onWishlistTap,
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
