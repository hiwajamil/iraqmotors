import '../core/filter_l10n.dart';

/// User-selected values for the home advanced search panel.
class AdvancedFilterState {
  const AdvancedFilterState({
    this.modelKey,
    this.year,
    this.mileageKey,
    this.priceKey,
    this.conditionKey,
    this.engineKey,
    this.locationKey = LocationKeys.defaultRegion,
  });

  final String? modelKey;
  final String? year;
  final String? mileageKey;
  final String? priceKey;
  final String? conditionKey;
  final String? engineKey;
  final String locationKey;

  static const AdvancedFilterState empty = AdvancedFilterState();

  bool get hasAnySelection =>
      modelKey != null ||
      year != null ||
      mileageKey != null ||
      priceKey != null ||
      conditionKey != null ||
      engineKey != null;

  AdvancedFilterState copyWith({
    String? modelKey,
    String? year,
    String? mileageKey,
    String? priceKey,
    String? conditionKey,
    String? engineKey,
    String? locationKey,
    bool clearModel = false,
    bool clearYear = false,
    bool clearMileage = false,
    bool clearPrice = false,
    bool clearCondition = false,
    bool clearEngine = false,
  }) {
    return AdvancedFilterState(
      modelKey: clearModel ? null : (modelKey ?? this.modelKey),
      year: clearYear ? null : (year ?? this.year),
      mileageKey: clearMileage ? null : (mileageKey ?? this.mileageKey),
      priceKey: clearPrice ? null : (priceKey ?? this.priceKey),
      conditionKey: clearCondition ? null : (conditionKey ?? this.conditionKey),
      engineKey: clearEngine ? null : (engineKey ?? this.engineKey),
      locationKey: locationKey ?? this.locationKey,
    );
  }

  AdvancedFilterState cleared({String? keepLocationKey}) {
    return AdvancedFilterState(locationKey: keepLocationKey ?? locationKey);
  }
}
