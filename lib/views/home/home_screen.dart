import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/dummy_brands.dart';
import '../../models/advanced_filter_state.dart';
import '../../models/car_brand.dart';
import '../../core/l10n_extensions.dart';
import '../../data/localized_dummy_data.dart';
import '../../providers/auth_providers.dart';
import '../../widgets/brand_search_sheet.dart';
import '../../widgets/home_filter_section.dart';
import '../../widgets/language_switcher.dart';
import '../../widgets/premium_car_card.dart';
import '../auth/auth_screen.dart';
import '../listings/car_details_screen.dart';

/// Explore / home — glass nav, centered hero, filters, listing grid.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  static const Color _background = Color(0xFFF5F5F7);
  static const Color _textPrimary = Color(0xFF1D1D1F);
  static const Color _textSecondary = Color(0xFF86868B);

  /// Dummy listings — matches the HTML prototype exactly.
  static final List<Map<String, dynamic>> _cars =
      LocalizedDummyData.homeListings();

  CarBrand? _selectedBrand;
  AdvancedFilterState _advancedFilters = AdvancedFilterState.empty;
  bool _advancedFilterExpanded = false;
  late final AnimationController _heroController;

  bool get _showAdvancedFilter =>
      _selectedBrand != null || _advancedFilterExpanded;
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

  @override
  void dispose() {
    _heroController.dispose();
    super.dispose();
  }

  double _horizontalPadding(double width) => width * 0.08;

  int _gridCrossAxisCount(double width, double padding) {
    final available = width - (padding * 2);
    final count = (available / 350).floor();
    return count.clamp(1, 4);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final navLinks = [l10n.navAllModels, l10n.navTuning, l10n.navShowrooms];

    return Scaffold(
      backgroundColor: _background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isWide = width >= 768;
          final hPadding = _horizontalPadding(width);
          final crossAxisCount = _gridCrossAxisCount(width, hPadding);

          return CustomScrollView(
            slivers: [
              _GlassNavBar(
                isWide: isWide,
                navLinks: navLinks,
                horizontalPadding: hPadding,
              ),
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _heroFade,
                    child: SlideTransition(
                      position: _heroSlide,
                      child: _HeroSection(
                        isWide: isWide,
                        selectedBrand: _selectedBrand,
                        filterValues: _advancedFilters,
                        showAdvancedFilter: _showAdvancedFilter,
                        onAdvancedSearchToggle: () {
                          setState(() {
                            _advancedFilterExpanded = !_advancedFilterExpanded;
                          });
                        },
                        onBrandSelected: (brand) {
                          setState(() {
                            _selectedBrand = brand;
                            if (brand != null) _advancedFilterExpanded = true;
                          });
                        },
                        onFilterChanged: (values) {
                          setState(() => _advancedFilters = values);
                        },
                        onClearFilters: () {
                          setState(() {
                            _advancedFilters = _advancedFilters.cleared();
                          });
                        },
                        onShowResults: () {},
                        onViewAllBrands: () async {
                          final brand =
                              await BrandSearchSheet.show(context);
                          if (brand != null) {
                            setState(() {
                              _selectedBrand = brand;
                              _advancedFilterExpanded = true;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsetsDirectional.fromSTEB(
                    hPadding,
                    0,
                    hPadding,
                    0,
                  ),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 30,
                      crossAxisSpacing: 30,
                      mainAxisExtent: 480,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return PremiumCarCard(
                          car: _cars[index],
                          animationDelay: Duration(
                            milliseconds: 100 * (index + 1),
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => CarDetailsScreen(
                                  car: _cars[index],
                                ),
                              ),
                            );
                          },
                          onWishlistTap: () {},
                        );
                      },
                      childCount: _cars.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: _Footer(),
                ),
              ],
            );
          },
        ),
    );
  }
}

class _GlassNavBar extends StatelessWidget {
  const _GlassNavBar({
    required this.isWide,
    required this.navLinks,
    required this.horizontalPadding,
  });

  final bool isWide;
  final List<String> navLinks;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const verticalPadding = 20.0;
    const contentHeight = 44.0;
    final topInset = MediaQuery.paddingOf(context).top;
    final toolbarHeight =
        topInset + verticalPadding * 2 + contentHeight;

    return SliverAppBar(
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: toolbarHeight,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              border: Border(
                bottom: BorderSide(
                  color: Colors.black.withValues(alpha: 0.05),
                ),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  horizontalPadding,
                  verticalPadding,
                  horizontalPadding,
                  verticalPadding,
                ),
                child: SizedBox(
                  height: contentHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        l10n.appTitle,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          height: 1.0,
                          color: Color(0xFF1D1D1F),
                        ),
                      ),
                    if (isWide) ...[
                      const Spacer(),
                      ...navLinks.map(
                        (link) => Padding(
                          padding: const EdgeInsetsDirectional.only(
                            start: 32,
                          ),
                          child: _NavLink(label: link),
                        ),
                      ),
                      const Spacer(),
                    ] else
                      const Spacer(),
                    const LanguageSwitcherButton(),
                    const SizedBox(width: 15),
                    Consumer(
                      builder: (context, ref, _) {
                        final user = ref.watch(authStateProvider).value;
                        final profile = ref.watch(userProfileProvider).value;
                        final isSignedIn = user != null;
                        final label = isSignedIn && profile != null
                            ? profile.displayName
                            : l10n.myAccount;

                        return _AccountButton(
                          label: label,
                          onTap: () async {
                            if (isSignedIn) {
                              final action = await showMenu<String>(
                                context: context,
                                position: const RelativeRect.fromLTRB(
                                  1000,
                                  80,
                                  0,
                                  0,
                                ),
                                items: [
                                  PopupMenuItem(
                                    value: 'sign_out',
                                    child: Text(l10n.signOut),
                                  ),
                                ],
                              );
                              if (action == 'sign_out') {
                                await ref
                                    .read(authServiceProvider)
                                    .signOut();
                              }
                            } else {
                              if (!context.mounted) return;
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const AuthScreen(),
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavLink extends StatefulWidget {
  const _NavLink({required this.label});

  final String label;

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () {},
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _hovered ? 1 : 0.7,
          child: Text(
            widget.label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _HomeScreenState._textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountButton extends StatefulWidget {
  const _AccountButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  State<_AccountButton> createState() => _AccountButtonState();
}

class _AccountButtonState extends State<_AccountButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovered ? 1.05 : 1,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 24,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: _hovered ? Colors.black : _HomeScreenState._textPrimary,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              widget.label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.isWide,
    required this.selectedBrand,
    required this.filterValues,
    required this.showAdvancedFilter,
    required this.onBrandSelected,
    required this.onFilterChanged,
    required this.onClearFilters,
    required this.onShowResults,
    required this.onViewAllBrands,
    required this.onAdvancedSearchToggle,
  });

  final bool isWide;
  final CarBrand? selectedBrand;
  final AdvancedFilterState filterValues;
  final bool showAdvancedFilter;
  final ValueChanged<CarBrand?> onBrandSelected;
  final ValueChanged<AdvancedFilterState> onFilterChanged;
  final VoidCallback onClearFilters;
  final VoidCallback onShowResults;
  final VoidCallback onViewAllBrands;
  final VoidCallback onAdvancedSearchToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        20,
        isWide ? 100 : 72,
        20,
        0,
      ),
      child: Column(
        children: [
          Text(
            l10n.heroTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isWide ? 64 : 44.8,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.5,
              color: _HomeScreenState._textPrimary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 15),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Text(
              l10n.heroSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isWide ? 22.4 : 19.2,
                fontWeight: FontWeight.w400,
                color: _HomeScreenState._textSecondary,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 36),
          Center(
            child: HomeFilterSection(
              selectedBrand: selectedBrand,
              filterValues: filterValues,
              showAdvancedFilter: showAdvancedFilter,
              onFilterChanged: onFilterChanged,
              onClearFilters: onClearFilters,
              onShowResults: onShowResults,
              onAdvancedSearchToggle: onAdvancedSearchToggle,
            ),
          ),
          const SizedBox(height: 20),
          _BrandHorizontalStrip(
            selectedBrandId: selectedBrand?.id,
            onBrandSelected: onBrandSelected,
            onViewAllTap: onViewAllBrands,
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

/// Horizontally scrollable brand logos — logo above name.
class _BrandHorizontalStrip extends StatelessWidget {
  const _BrandHorizontalStrip({
    required this.selectedBrandId,
    required this.onBrandSelected,
    required this.onViewAllTap,
  });

  final String? selectedBrandId;
  final ValueChanged<CarBrand?> onBrandSelected;
  final VoidCallback onViewAllTap;

  static const Color _brandTextPrimary = Color(0xFF1D1D1F);
  static const Color _brandTextSecondary = Color(0xFF86868B);
  static const Color _brandFill = Color(0xFFE8E8ED);
  static const Color _brandSelectedRing = Color(0xFF1D1D1F);

  /// 1.5× prior ~64px discs — premium, prominent brand marks.
  static const double _circleSize = 100;
  static const double _logoPadding = 8;
  static const double _stripHeight = 180;
  static const double _itemWidth = 124;
  static const double _itemSpacing = 18;

  /// Clearbit Logo API — current high-quality marks from official domains.
  static String clearbitLogoUrl(CarBrand brand) {
    final host = _clearbitHosts[brand.id] ??
        '${brand.id.replaceAll('_', '-')}.com';
    return 'https://logo.clearbit.com/$host';
  }

  static const Map<String, String> _clearbitHosts = {
    'mercedes_benz': 'mercedes-benz.com',
    'land_rover': 'landrover.com',
    'gac_motor': 'gacgroup.com',
    'rolls_royce': 'rolls-roycemotorcars.com',
    'aston_martin': 'astonmartin.com',
    'alfa_romeo': 'alfaromeo.com',
    'great_wall': 'gwm-global.com',
    'li_auto': 'lixiang.com',
    'nio': 'nio.com',
    'xpeng': 'xiaopeng.com',
    'genesis': 'genesis.com',
    'mini': 'mini.com',
    'bentley': 'bentleymotors.com',
    'lamborghini': 'lamborghini.com',
    'maserati': 'maserati.com',
    'porsche': 'porsche.com',
  };

  @override
  Widget build(BuildContext context) {
    final itemCount = dummyBrands.length + 1;

    return SizedBox(
      height: _stripHeight,
      width: double.infinity,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        primary: false,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        clipBehavior: Clip.none,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 4),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          final isLast = index == dummyBrands.length;
          return Padding(
            padding: EdgeInsetsDirectional.only(
              start: index == 0 ? 0 : _itemSpacing,
            ),
            child: isLast
                ? _BrandMoreChip(onTap: onViewAllTap)
                : _BrandItem(
                    brand: dummyBrands[index],
                    isSelected: selectedBrandId == dummyBrands[index].id,
                    onTap: () {
                      final brand = dummyBrands[index];
                      final isSelected = selectedBrandId == brand.id;
                      onBrandSelected(isSelected ? null : brand);
                    },
                  ),
          );
        },
      ),
    );
  }
}

/// Circular brand mark — white disc, soft shadow, edge-to-edge logo.
class _BrandLogoCircle extends StatelessWidget {
  const _BrandLogoCircle({
    required this.brand,
    required this.fallbackLetter,
    required this.isSelected,
  });

  final CarBrand brand;
  final String fallbackLetter;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      width: _BrandHorizontalStrip._circleSize,
      height: _BrandHorizontalStrip._circleSize,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isSelected ? 0.1 : 0.05),
            blurRadius: isSelected ? 14 : 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isSelected
              ? _BrandHorizontalStrip._brandSelectedRing
              : _BrandHorizontalStrip._brandFill,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ClipOval(
        child: Padding(
          padding:
              const EdgeInsets.all(_BrandHorizontalStrip._logoPadding),
          child: _BrandLogoImage(
            brand: brand,
            fallbackLetter: fallbackLetter,
          ),
        ),
      ),
    );
  }
}

/// Clearbit first, then CDN [CarBrand.logoUrl], then letter fallback.
class _BrandLogoImage extends StatefulWidget {
  const _BrandLogoImage({
    required this.brand,
    required this.fallbackLetter,
  });

  final CarBrand brand;
  final String fallbackLetter;

  @override
  State<_BrandLogoImage> createState() => _BrandLogoImageState();
}

class _BrandLogoImageState extends State<_BrandLogoImage> {
  int _sourceIndex = 0;

  List<String> get _urls => [
        _BrandHorizontalStrip.clearbitLogoUrl(widget.brand),
        widget.brand.logoUrl,
      ];

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: _urls[_sourceIndex],
      fit: BoxFit.contain,
      placeholder: (_, __) => const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (_, __, ___) {
        if (_sourceIndex < _urls.length - 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _sourceIndex < _urls.length - 1) {
              setState(() => _sourceIndex++);
            }
          });
          return const SizedBox.shrink();
        }
        return Center(
          child: Text(
            widget.fallbackLetter,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: _BrandHorizontalStrip._brandTextSecondary,
            ),
          ),
        );
      },
    );
  }
}

class _BrandItem extends StatefulWidget {
  const _BrandItem({
    required this.brand,
    required this.isSelected,
    required this.onTap,
  });

  final CarBrand brand;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_BrandItem> createState() => _BrandItemState();
}

class _BrandItemState extends State<_BrandItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1,
        duration: const Duration(milliseconds: 120),
        child: SizedBox(
          width: _BrandHorizontalStrip._itemWidth,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _BrandLogoCircle(
                brand: widget.brand,
                fallbackLetter: widget.brand.nameEnglish[0].toUpperCase(),
                isSelected: widget.isSelected,
              ),
              const SizedBox(height: 10),
              Text(
                widget.brand.displayName(lang),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: widget.isSelected
                      ? _BrandHorizontalStrip._brandTextPrimary
                      : _BrandHorizontalStrip._brandTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandMoreChip extends StatefulWidget {
  const _BrandMoreChip({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_BrandMoreChip> createState() => _BrandMoreChipState();
}

class _BrandMoreChipState extends State<_BrandMoreChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1,
        duration: const Duration(milliseconds: 120),
        child: SizedBox(
          width: _BrandHorizontalStrip._itemWidth,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: _BrandHorizontalStrip._circleSize,
                height: _BrandHorizontalStrip._circleSize,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: _BrandHorizontalStrip._brandFill,
                    width: 1,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.grid_view_rounded,
                    size: 32,
                    color: _BrandHorizontalStrip._brandTextPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'زیاتر',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _BrandHorizontalStrip._brandTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 40),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 20,
        vertical: 40,
      ),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFFE5E5EA)),
        ),
      ),
      child: Text(
        l10n.footerCopyright,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          color: _HomeScreenState._textSecondary,
        ),
      ),
    );
  }
}
