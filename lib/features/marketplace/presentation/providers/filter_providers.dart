import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iq_motors/shared/data/car_models_by_brand.dart';
import 'package:iq_motors/features/marketplace/domain/models/advanced_filter_state.dart';
import 'package:iq_motors/shared/models/car_brand.dart';
import 'package:iq_motors/features/marketplace/domain/models/home_filter_state.dart';
import 'package:iq_motors/features/marketplace/data/services/car_filter_service.dart';
import 'package:iq_motors/features/storage/presentation/providers/storage_providers.dart';

/// Currently selected home-feed filters (brand, model, year, price, etc.).
final filterStateProvider =
    NotifierProvider<FilterStateNotifier, HomeFilterState>(
  FilterStateNotifier.new,
);

class FilterStateNotifier extends Notifier<HomeFilterState> {
  @override
  HomeFilterState build() => const HomeFilterState();

  void setBrand(CarBrand? brand) {
    state = state.copyWith(
      brand: brand,
      clearBrand: brand == null,
      filters: _filtersAfterBrandChange(state.filters, brand),
      advancedFilterExpanded: brand != null ? true : state.advancedFilterExpanded,
    );
  }

  void setFilters(AdvancedFilterState filters) {
    state = state.copyWith(filters: filters);
  }

  void setAdvancedFilterExpanded(bool expanded) {
    state = state.copyWith(advancedFilterExpanded: expanded);
  }

  void clearFilters() {
    state = state.copyWith(
      filters: state.filters.cleared(
        keepLocationKeys: state.filters.selectedLocationKeys,
      ),
    );
  }

  void applyAdvancedFilterResult(AdvancedFilterResult result) {
    state = HomeFilterState(
      brand: result.brand,
      filters: result.filters,
      advancedFilterExpanded:
          result.brand != null || state.advancedFilterExpanded,
    );
  }

  AdvancedFilterState _filtersAfterBrandChange(
    AdvancedFilterState filters,
    CarBrand? brand,
  ) {
    final modelKey = filters.modelKey;
    if (modelKey == null) return filters;
    if (brand == null) {
      return filters.copyWith(clearModel: true);
    }
    if (!CarModelsByBrand.isValidModelSelection(brand, modelKey)) {
      return filters.copyWith(clearModel: true);
    }
    return filters;
  }
}

/// Live home-feed listings filtered by [filterStateProvider].
final homeCarsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final homeFilter = ref.watch(filterStateProvider);
  final query = CarFilterService.toFirestoreQuery(homeFilter);
  final db = ref.watch(carDatabaseServiceProvider);

  return db.watchFilteredActiveCars(query).map((cars) {
    final maps = cars.map((car) => car.toMap()).toList();
    return CarFilterService.applyClientFilters(maps, homeFilter);
  });
});
