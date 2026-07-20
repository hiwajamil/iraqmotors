import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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
      // Expand when a brand is selected; collapse fully when deselected.
      advancedFilterExpanded: brand != null,
    );
  }

  void setFilters(AdvancedFilterState filters) {
    state = state.copyWith(filters: filters);
  }

  void collapseAdvancedFilter() {
    state = state.copyWith(advancedFilterExpanded: false);
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

/// Paginated home-feed listings filtered by [filterStateProvider].
final homeCarsProvider =
    AsyncNotifierProvider<HomeCarsNotifier, List<Map<String, dynamic>>>(
      HomeCarsNotifier.new,
    );

class HomeCarsNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  static const int _pageSize = 12;
  static const int _maxBatchesPerPage = 4;

  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  final List<Map<String, dynamic>> _overflowBuffer = [];

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  @override
  Future<List<Map<String, dynamic>>> build() async {
    _lastDoc = null;
    _hasMore = true;
    _isLoadingMore = false;
    _overflowBuffer.clear();

    final homeFilter = ref.watch(filterStateProvider);
    return _fetchPage(homeFilter, isRefresh: true);
  }

  Future<void> fetchNextPage() async {
    if (!_hasMore || _isLoadingMore || state.isLoading || state.hasError) {
      return;
    }
    _isLoadingMore = true;
    // Notify listeners so the footer spinner appears.
    state = AsyncData(state.value ?? []);

    final homeFilter = ref.read(filterStateProvider);
    try {
      final newCars = await _fetchPage(homeFilter, isRefresh: false);
      final currentList = state.value ?? [];
      state = AsyncData([...currentList, ...newCars]);
    } catch (e) {
      // Don't overwrite state with error — preserve current feed.
      debugPrint('fetchNextPage error: $e');
      state = AsyncData(state.value ?? []);
    } finally {
      _isLoadingMore = false;
      state = AsyncData(state.value ?? []);
    }
  }

  /// Fetches until [pageSize] client-filtered cars are collected, Firestore is
  /// exhausted, or [_maxBatchesPerPage] is hit — avoiding empty/short pages
  /// when price/mileage/year are applied client-side.
  Future<List<Map<String, dynamic>>> _fetchPage(
    HomeFilterState homeFilter, {
    required bool isRefresh,
  }) async {
    if (isRefresh) {
      _lastDoc = null;
      _overflowBuffer.clear();
      _hasMore = true;
    }

    final query = CarFilterService.toFirestoreQuery(homeFilter);
    final db = ref.read(carDatabaseServiceProvider);
    final collected = <Map<String, dynamic>>[];

    while (_overflowBuffer.isNotEmpty && collected.length < _pageSize) {
      collected.add(_overflowBuffer.removeAt(0));
    }

    var batches = 0;
    var exhausted = false;

    while (collected.length < _pageSize &&
        batches < _maxBatchesPerPage &&
        !exhausted) {
      batches++;
      final (cars, lastDoc) = await db.fetchFilteredActiveCarsPage(
        query,
        startAfter: _lastDoc,
        limit: _pageSize,
      );

      _lastDoc = lastDoc;
      if (cars.length < _pageSize) {
        exhausted = true;
      }

      final maps = cars.map((car) => car.toMap()).toList();
      final filtered = CarFilterService.applyClientFilters(maps, homeFilter);

      for (final car in filtered) {
        if (collected.length < _pageSize) {
          collected.add(car);
        } else {
          _overflowBuffer.add(car);
        }
      }
    }

    if (exhausted && _overflowBuffer.isEmpty) {
      _hasMore = false;
    } else if (collected.length < _pageSize &&
        batches >= _maxBatchesPerPage &&
        !exhausted) {
      // Budget hit with room left — more matching docs may still exist.
      _hasMore = true;
    } else {
      _hasMore = !exhausted || _overflowBuffer.isNotEmpty;
    }

    return collected;
  }
}
