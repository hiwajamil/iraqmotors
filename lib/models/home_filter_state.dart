import 'advanced_filter_state.dart';
import 'car_brand.dart';

/// Brand + advanced filters driving the public home feed.
class HomeFilterState {
  const HomeFilterState({
    this.brand,
    this.filters = AdvancedFilterState.empty,
    this.advancedFilterExpanded = false,
  });

  final CarBrand? brand;
  final AdvancedFilterState filters;
  final bool advancedFilterExpanded;

  bool get showAdvancedFilter => brand != null || advancedFilterExpanded;

  HomeFilterState copyWith({
    CarBrand? brand,
    AdvancedFilterState? filters,
    bool? advancedFilterExpanded,
    bool clearBrand = false,
  }) {
    return HomeFilterState(
      brand: clearBrand ? null : (brand ?? this.brand),
      filters: filters ?? this.filters,
      advancedFilterExpanded:
          advancedFilterExpanded ?? this.advancedFilterExpanded,
    );
  }
}
