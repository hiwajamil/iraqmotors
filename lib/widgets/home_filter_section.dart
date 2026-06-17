import 'package:flutter/material.dart';

import '../models/advanced_filter_state.dart';
import '../models/car_brand.dart';
import 'advanced_filter_widget.dart';
import 'location_picker_sheet.dart';

/// Header and expandable advanced filter for home explore.
class HomeFilterSection extends StatelessWidget {
  const HomeFilterSection({
    super.key,
    required this.selectedBrand,
    required this.filterValues,
    required this.showAdvancedFilter,
    required this.onFilterChanged,
    required this.onClearFilters,
    required this.onShowResults,
    this.onAdvancedSearchToggle,
    this.resultCount = 734,
  });

  final CarBrand? selectedBrand;
  final AdvancedFilterState filterValues;
  final bool showAdvancedFilter;
  final ValueChanged<AdvancedFilterState> onFilterChanged;
  final VoidCallback onClearFilters;
  final VoidCallback onShowResults;
  final VoidCallback? onAdvancedSearchToggle;
  final int resultCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
          AdvancedFilterHeader(
            selectedLocationKeys: filterValues.selectedLocationKeys,
            onLocationTap: () => _pickLocation(context),
            onAdvancedSearchTap: onAdvancedSearchToggle,
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -0.04),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: showAdvancedFilter
                  ? Padding(
                      key: ValueKey(selectedBrand?.id ?? 'advanced'),
                      padding: const EdgeInsets.only(top: 20),
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
                    )
                  : const SizedBox.shrink(key: ValueKey('collapsed')),
            ),
          ),
      ],
    );
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
}
