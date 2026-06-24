import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:iq_motors/core/localization/l10n_extensions.dart';
import 'package:iq_motors/features/marketplace/domain/models/advanced_filter_state.dart';
import 'package:iq_motors/shared/models/car_brand.dart';
import 'package:iq_motors/features/marketplace/presentation/widgets/advanced_filter_widget.dart';
import 'package:iq_motors/shared/widgets/location_picker_sheet.dart';
import 'package:iq_motors/features/marketplace/presentation/widgets/home/home_brand_strip.dart';
import 'package:iq_motors/features/marketplace/presentation/widgets/home/home_glass_nav_bar.dart';
import 'package:iq_motors/features/marketplace/presentation/widgets/home/home_theme.dart';

/// Cinematic hero with background image, headline, and filter header.
class HomeHeroSection extends StatelessWidget {
  const HomeHeroSection({
    super.key,
    required this.isWide,
    required this.selectedBrand,
    required this.filterValues,
    required this.showAdvancedFilter,
    required this.onBrandSelected,
    required this.onFilterChanged,
    required this.onClearFilters,
    required this.onShowResults,
    required this.resultCount,
    required this.onViewAllBrands,
    required this.onAdvancedSearchToggle,
  });

  static const String heroBackgroundAsset = 'assets/hero_bg.jpg';

  static const List<Shadow> _headlineShadow = [
    Shadow(
      blurRadius: 16,
      color: Color(0x66000000),
      offset: Offset(0, 2),
    ),
    Shadow(
      blurRadius: 4,
      color: Color(0x40000000),
      offset: Offset(0, 1),
    ),
  ];

  final bool isWide;
  final CarBrand? selectedBrand;
  final AdvancedFilterState filterValues;
  final bool showAdvancedFilter;
  final ValueChanged<CarBrand?> onBrandSelected;
  final ValueChanged<AdvancedFilterState> onFilterChanged;
  final VoidCallback onClearFilters;
  final VoidCallback onShowResults;
  final int resultCount;
  final VoidCallback onViewAllBrands;
  final VoidCallback onAdvancedSearchToggle;

  /// Mobile hero height — must keep min ≤ max or [num.clamp] throws.
  static double mobileHeroHeight(double screenHeight) {
    final maxHeight = screenHeight * 0.40;
    final minHeight = maxHeight < 280.0 ? maxHeight : 280.0;
    return (screenHeight * 0.34).clamp(minHeight, maxHeight);
  }

  double _heroHeight(BuildContext context) {
    if (isWide) return 600;
    return mobileHeroHeight(MediaQuery.sizeOf(context).height);
  }

  Future<void> _pickLocation(BuildContext context) async {
    final picked = await showLocationPickerSheet(
      context,
      initialSelection: filterValues.selectedLocationKeys,
    );
    if (picked != null) {
      onFilterChanged(
        filterValues.copyWith(selectedLocationKeys: picked),
      );
    }
  }

  Widget _filterHeader(BuildContext context, {required bool heroStyle}) {
    return AdvancedFilterHeader(
      heroStyle: heroStyle,
      selectedLocationKeys: filterValues.selectedLocationKeys,
      onLocationTap: () => _pickLocation(context),
      onAdvancedSearchTap: onAdvancedSearchToggle,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isWide) {
      return _buildMobileLayout(context);
    }
    return _buildWideLayout(context);
  }

  Widget _buildMobileLayout(BuildContext context) {
    final l10n = context.l10n;
    final heroHeight = _heroHeight(context);
    final navHeight = HomeGlassNavBar.heightOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: heroHeight,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                heroBackgroundAsset,
                fit: BoxFit.cover,
                width: double.infinity,
                cacheWidth: (MediaQuery.sizeOf(context).width *
                        MediaQuery.devicePixelRatioOf(context))
                    .round(),
              ),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x33000000),
                      Color(0x00000000),
                      Color(0xCCFFFFFF),
                    ],
                    stops: [0.0, 0.45, 1.0],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(20, navHeight, 20, 0),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    l10n.heroTitle,
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.8,
                      color: Colors.white,
                      height: 1.15,
                      shadows: _headlineShadow,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _filterHeader(context, heroStyle: false),
          ),
        ),
        const SizedBox(height: 4),
        if (showAdvancedFilter)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
            child: AdvancedFilterWidget(
              showHeader: false,
              selectedBrand: selectedBrand,
              values: filterValues,
              onChanged: onFilterChanged,
              onClear: onClearFilters,
              onShowResults: onShowResults,
              resultCount: resultCount,
              onLocationTap: () => _pickLocation(context),
            ),
          ),
        HomeSectionTitle(title: l10n.homeBrowseBrands),
        HomeBrandHorizontalStrip(
          isWide: false,
          selectedBrandId: selectedBrand?.id,
          onBrandSelected: onBrandSelected,
          onViewAllTap: onViewAllBrands,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _heroHeight(context),
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                heroBackgroundAsset,
                fit: BoxFit.cover,
                width: double.infinity,
                cacheWidth: (MediaQuery.sizeOf(context).width *
                        MediaQuery.devicePixelRatioOf(context))
                    .round(),
              ),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Color(0x00FFFFFF),
                      Colors.white,
                    ],
                    stops: [0.0, 0.55, 1.0],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 48, 20, 56),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.heroTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1.5,
                        color: Colors.white,
                        height: 1.1,
                        shadows: _headlineShadow,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: Text(
                        l10n.heroSubtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.7),
                          height: 1.5,
                          shadows: _headlineShadow,
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: _heroFilterShell(
                          child: _filterHeader(context, heroStyle: true),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showAdvancedFilter)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 850),
                child: AdvancedFilterWidget(
                  showHeader: false,
                  selectedBrand: selectedBrand,
                  values: filterValues,
                  onChanged: onFilterChanged,
                  onClear: onClearFilters,
                  onShowResults: onShowResults,
                  resultCount: resultCount,
                  onLocationTap: () => _pickLocation(context),
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        HomeBrandHorizontalStrip(
          isWide: true,
          selectedBrandId: selectedBrand?.id,
          onBrandSelected: onBrandSelected,
          onViewAllTap: onViewAllBrands,
        ),
        const SizedBox(height: 48),
      ],
    );
  }

  Widget _heroFilterShell({required Widget child}) {
    final shell = Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: kIsWeb ? 0.1 : 0.18),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: child,
    );

    if (kIsWeb) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: shell,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: shell,
    );
  }
}
