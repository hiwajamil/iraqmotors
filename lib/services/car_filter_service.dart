import '../core/filter_l10n.dart';
import '../models/advanced_filter_state.dart';
import '../models/home_filter_state.dart';

/// Equality filters applied directly on Firestore queries.
class CarFirestoreFilterQuery {
  const CarFirestoreFilterQuery({
    this.brandId,
    this.modelKey,
    this.year,
    this.conditionKey,
    this.fuelKey,
    this.colorKey,
    this.transmissionKey,
    this.plateCityKey,
    this.plateTypeKey,
    this.engineSizeKey,
    this.cylindersKey,
    this.importCountryKey,
    this.seatMaterialKey,
  });

  final String? brandId;
  final String? modelKey;
  final String? year;
  final String? conditionKey;
  final String? fuelKey;
  final String? colorKey;
  final String? transmissionKey;
  final String? plateCityKey;
  final String? plateTypeKey;
  final String? engineSizeKey;
  final String? cylindersKey;
  final String? importCountryKey;
  final String? seatMaterialKey;

  bool get hasEqualityFilters =>
      brandId != null ||
      modelKey != null ||
      year != null ||
      conditionKey != null ||
      fuelKey != null ||
      colorKey != null ||
      transmissionKey != null ||
      plateCityKey != null ||
      plateTypeKey != null ||
      engineSizeKey != null ||
      cylindersKey != null ||
      importCountryKey != null ||
      seatMaterialKey != null;
}

/// Applies home advanced-search filters to car listing maps.
abstract final class CarFilterService {
  static const Map<String, String> _trimKeyToStoredValue = {
    FilterOptionKeys.trimBase: 'Base',
    FilterOptionKeys.trimSport: 'Sport',
    FilterOptionKeys.trimLuxury: 'Luxury',
  };

  static CarFirestoreFilterQuery toFirestoreQuery(HomeFilterState state) {
    final filters = state.filters;
    return CarFirestoreFilterQuery(
      brandId: state.brand?.id,
      modelKey: filters.modelKey,
      year: filters.year,
      conditionKey: filters.conditionKey,
      fuelKey: filters.engineKey,
      colorKey: filters.colorKey,
      transmissionKey: filters.transmissionKey,
      plateCityKey: filters.plateCityKey,
      plateTypeKey: filters.plateTypeKey,
      engineSizeKey: filters.engineSizeKey,
      cylindersKey: filters.cylindersKey,
      importCountryKey: filters.importCountryKey,
      seatMaterialKey: filters.seatMaterialKey,
    );
  }

  static List<Map<String, dynamic>> applyClientFilters(
    List<Map<String, dynamic>> cars,
    HomeFilterState state,
  ) {
    if (cars.isEmpty) return cars;
    return cars.where((car) => matchesCar(car, state)).toList();
  }

  static bool matchesCar(Map<String, dynamic> car, HomeFilterState state) {
    final filters = state.filters;

    if (state.brand != null &&
        car['brandId']?.toString() != state.brand!.id) {
      return false;
    }

    if (filters.modelKey != null &&
        car['modelKey']?.toString() != filters.modelKey) {
      return false;
    }

    if (filters.year != null && car['year']?.toString() != filters.year) {
      return false;
    }

    if (!_matchesYearRange(car, filters)) return false;

    if (filters.conditionKey != null &&
        car['conditionKey']?.toString() != filters.conditionKey) {
      return false;
    }

    if (filters.engineKey != null &&
        car['fuelKey']?.toString() != filters.engineKey) {
      return false;
    }

    if (filters.colorKey != null &&
        car['colorKey']?.toString() != filters.colorKey) {
      return false;
    }

    if (filters.transmissionKey != null &&
        car['transmissionKey']?.toString() != filters.transmissionKey) {
      return false;
    }

    if (filters.plateCityKey != null &&
        car['plateCityKey']?.toString() != filters.plateCityKey) {
      return false;
    }

    if (filters.plateTypeKey != null &&
        car['plateTypeKey']?.toString() != filters.plateTypeKey) {
      return false;
    }

    if (filters.engineSizeKey != null &&
        car['engineSizeKey']?.toString() != filters.engineSizeKey) {
      return false;
    }

    if (filters.cylindersKey != null &&
        car['cylindersKey']?.toString() != filters.cylindersKey) {
      return false;
    }

    if (filters.importCountryKey != null &&
        car['importCountryKey']?.toString() != filters.importCountryKey) {
      return false;
    }

    if (filters.seatMaterialKey != null &&
        car['seatMaterialKey']?.toString() != filters.seatMaterialKey) {
      return false;
    }

    if (filters.trimKey != null && !_matchesTrim(car, filters.trimKey!)) {
      return false;
    }

    if (!_matchesLocation(car, filters.selectedLocationKeys)) return false;

    final price = _coerceNum(car['priceValue']);
    if (price != null && !_matchesPrice(price, filters)) return false;
    if (price == null && _hasPriceFilter(filters)) return false;

    final mileage = _coerceNum(car['mileageValue']);
    if (mileage != null && !_matchesMileage(mileage, filters)) return false;
    if (mileage == null && _hasMileageFilter(filters)) return false;

    return true;
  }

  static bool _matchesYearRange(Map<String, dynamic> car, AdvancedFilterState filters) {
    final year = int.tryParse(car['year']?.toString() ?? '');
    if (year == null) {
      return filters.fromYear == null && filters.toYear == null;
    }

    final fromYear = int.tryParse(filters.fromYear ?? '');
    if (fromYear != null && year < fromYear) return false;

    final toYear = int.tryParse(filters.toYear ?? '');
    if (toYear != null && year > toYear) return false;

    return true;
  }

  static bool _matchesTrim(Map<String, dynamic> car, String trimKey) {
    final expected = _trimKeyToStoredValue[trimKey];
    if (expected == null) return true;
    final trim = car['trim']?.toString().trim().toLowerCase();
    return trim == expected.toLowerCase();
  }

  static bool _matchesLocation(
    Map<String, dynamic> car,
    Set<String> selectedLocationKeys,
  ) {
    if (LocationKeys.isAllCountry(selectedLocationKeys)) return true;

    final plateCity = car['plateCityKey']?.toString();
    if (plateCity != null && selectedLocationKeys.contains(plateCity)) {
      return true;
    }

    return false;
  }

  static bool _hasPriceFilter(AdvancedFilterState filters) =>
      filters.priceKey != null ||
      filters.minPriceKey != null ||
      filters.maxPriceKey != null;

  static bool _hasMileageFilter(AdvancedFilterState filters) =>
      filters.mileageKey != null ||
      filters.minMileageKey != null ||
      filters.maxMileageKey != null;

  static bool _matchesPrice(num price, AdvancedFilterState filters) {
    final bounds = _priceBounds(filters);
    if (bounds.min != null && price < bounds.min!) return false;
    if (bounds.max != null && price > bounds.max!) return false;
    return true;
  }

  static bool _matchesMileage(num mileage, AdvancedFilterState filters) {
    final bounds = _mileageBounds(filters);
    if (bounds.min != null && mileage < bounds.min!) return false;
    if (bounds.max != null && mileage > bounds.max!) return false;
    return true;
  }

  static _NumericBounds _priceBounds(AdvancedFilterState filters) {
    num? min;
    num? max;

    void applyKey(String? key) {
      if (key == null) return;
      final keyMin = _minForPriceKey(key);
      final keyMax = _maxForPriceKey(key);
      if (keyMin != null) min = min == null ? keyMin : (min! > keyMin ? min : keyMin);
      if (keyMax != null) max = max == null ? keyMax : (max! < keyMax ? max : keyMax);
    }

    applyKey(filters.minPriceKey);
    applyKey(filters.maxPriceKey);
    applyKey(filters.priceKey);

    return _NumericBounds(min: min, max: max);
  }

  static _NumericBounds _mileageBounds(AdvancedFilterState filters) {
    num? min;
    num? max;

    void applyKey(String? key) {
      if (key == null) return;
      final keyMin = _minForMileageKey(key);
      final keyMax = _maxForMileageKey(key);
      if (keyMin != null) min = min == null ? keyMin : (min! > keyMin ? min : keyMin);
      if (keyMax != null) max = max == null ? keyMax : (max! < keyMax ? max : keyMax);
    }

    applyKey(filters.minMileageKey);
    applyKey(filters.maxMileageKey);
    applyKey(filters.mileageKey);

    return _NumericBounds(min: min, max: max);
  }

  static num? _minForPriceKey(String key) => switch (key) {
        FilterOptionKeys.price100kPlus => 100000,
        _ => null,
      };

  static num? _maxForPriceKey(String key) => switch (key) {
        FilterOptionKeys.price20k => 20000,
        FilterOptionKeys.price50k => 50000,
        FilterOptionKeys.price100k => 100000,
        _ => null,
      };

  static num? _minForMileageKey(String key) => switch (key) {
        FilterOptionKeys.mileage100kPlus => 100000,
        _ => null,
      };

  static num? _maxForMileageKey(String key) => switch (key) {
        FilterOptionKeys.mileage0 => 0,
        FilterOptionKeys.mileage10k => 10000,
        FilterOptionKeys.mileage50k => 50000,
        FilterOptionKeys.mileage100k => 100000,
        _ => null,
      };

  static num? _coerceNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    return num.tryParse(value.toString());
  }
}

class _NumericBounds {
  const _NumericBounds({this.min, this.max});

  final num? min;
  final num? max;
}
