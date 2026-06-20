import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/l10n_extensions.dart';
import '../../models/advanced_filter_state.dart';
import '../../models/car_brand.dart';
import '../../widgets/advanced_filter_widget.dart';
import '../../widgets/location_picker_sheet.dart';
import 'home_brand_strip.dart';
import 'home_glass_nav_bar.dart';

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

  double _heroHeight(BuildContext context) {
    if (isWide) return 600;
    final screenHeight = MediaQuery.sizeOf(context).height;
    return (screenHeight * 0.5).clamp(450.0, screenHeight * 0.55);
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

  @override
  Widget build(BuildContext context) {
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
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: const [
                      Colors.transparent,
                      Color(0x00FFFFFF),
                      Colors.white,
                    ],
                    stops: isWide
                        ? const [0.0, 0.55, 1.0]
                        : const [0.0, 0.82, 1.0],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  20,
                  isWide ? 48 : 0,
                  20,
                  isWide ? 56 : 0,
                ),
                child: Column(
                  mainAxisAlignment: isWide
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
                  children: [
                    if (!isWide)
                      SizedBox(height: HomeGlassNavBar.heightOf(context)),
                    Text(
                      l10n.heroTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isWide ? 64 : 40,
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
                          fontSize: isWide ? 22 : 18,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.7),
                          height: 1.5,
                          shadows: _headlineShadow,
                        ),
                      ),
                    ),
                    SizedBox(height: isWide ? 36 : 28),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              child: AdvancedFilterHeader(
                                heroStyle: true,
                                selectedLocationKeys:
                                    filterValues.selectedLocationKeys,
                                onLocationTap: () => _pickLocation(context),
                                onAdvancedSearchTap: onAdvancedSearchToggle,
                              ),
                            ),
                          ),
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
          isWide: isWide,
          selectedBrandId: selectedBrand?.id,
          onBrandSelected: onBrandSelected,
          onViewAllTap: onViewAllBrands,
        ),
        const SizedBox(height: 48),
      ],
    );
  }
}
