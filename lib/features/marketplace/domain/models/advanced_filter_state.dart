import 'package:iq_motors/core/localization/filter_l10n.dart';
import 'package:iq_motors/shared/models/car_brand.dart';

/// User-selected values for advanced search / filter screens.
class AdvancedFilterState {
  const AdvancedFilterState({
    this.modelKey,
    this.trimKey,
    this.year,
    this.fromYear,
    this.toYear,
    this.mileageKey,
    this.minMileageKey,
    this.maxMileageKey,
    this.priceKey,
    this.minPriceKey,
    this.maxPriceKey,
    this.conditionKey,
    this.engineKey,
    this.plateCityKey,
    this.plateTypeKey,
    this.engineSizeKey,
    this.cylindersKey,
    this.importCountryKey,
    this.colorKey,
    this.transmissionKey,
    this.seatMaterialKey,
    this.selectedLocationKeys = LocationKeys.defaultSelection,
  });

  final String? modelKey;
  final String? trimKey;
  final String? year;
  final String? fromYear;
  final String? toYear;
  final String? mileageKey;
  final String? minMileageKey;
  final String? maxMileageKey;
  final String? priceKey;
  final String? minPriceKey;
  final String? maxPriceKey;
  final String? conditionKey;
  final String? engineKey;
  final String? plateCityKey;
  final String? plateTypeKey;
  final String? engineSizeKey;
  final String? cylindersKey;
  final String? importCountryKey;
  final String? colorKey;
  final String? transmissionKey;
  final String? seatMaterialKey;
  final Set<String> selectedLocationKeys;

  static const AdvancedFilterState empty = AdvancedFilterState();

  bool get hasAnySelection =>
      modelKey != null ||
      trimKey != null ||
      year != null ||
      fromYear != null ||
      toYear != null ||
      mileageKey != null ||
      minMileageKey != null ||
      maxMileageKey != null ||
      priceKey != null ||
      minPriceKey != null ||
      maxPriceKey != null ||
      conditionKey != null ||
      engineKey != null ||
      plateCityKey != null ||
      plateTypeKey != null ||
      engineSizeKey != null ||
      cylindersKey != null ||
      importCountryKey != null ||
      colorKey != null ||
      transmissionKey != null ||
      seatMaterialKey != null;

  AdvancedFilterState copyWith({
    String? modelKey,
    String? trimKey,
    String? year,
    String? fromYear,
    String? toYear,
    String? mileageKey,
    String? minMileageKey,
    String? maxMileageKey,
    String? priceKey,
    String? minPriceKey,
    String? maxPriceKey,
    String? conditionKey,
    String? engineKey,
    String? plateCityKey,
    String? plateTypeKey,
    String? engineSizeKey,
    String? cylindersKey,
    String? importCountryKey,
    String? colorKey,
    String? transmissionKey,
    String? seatMaterialKey,
    Set<String>? selectedLocationKeys,
    bool clearModel = false,
    bool clearTrim = false,
    bool clearYear = false,
    bool clearFromYear = false,
    bool clearToYear = false,
    bool clearMileage = false,
    bool clearMinMileage = false,
    bool clearMaxMileage = false,
    bool clearPrice = false,
    bool clearMinPrice = false,
    bool clearMaxPrice = false,
    bool clearCondition = false,
    bool clearEngine = false,
    bool clearPlateCity = false,
    bool clearPlateType = false,
    bool clearEngineSize = false,
    bool clearCylinders = false,
    bool clearImportCountry = false,
    bool clearColor = false,
    bool clearTransmission = false,
    bool clearSeatMaterial = false,
  }) {
    return AdvancedFilterState(
      modelKey: clearModel ? null : (modelKey ?? this.modelKey),
      trimKey: clearTrim ? null : (trimKey ?? this.trimKey),
      year: clearYear ? null : (year ?? this.year),
      fromYear: clearFromYear ? null : (fromYear ?? this.fromYear),
      toYear: clearToYear ? null : (toYear ?? this.toYear),
      mileageKey: clearMileage ? null : (mileageKey ?? this.mileageKey),
      minMileageKey:
          clearMinMileage ? null : (minMileageKey ?? this.minMileageKey),
      maxMileageKey:
          clearMaxMileage ? null : (maxMileageKey ?? this.maxMileageKey),
      priceKey: clearPrice ? null : (priceKey ?? this.priceKey),
      minPriceKey: clearMinPrice ? null : (minPriceKey ?? this.minPriceKey),
      maxPriceKey: clearMaxPrice ? null : (maxPriceKey ?? this.maxPriceKey),
      conditionKey:
          clearCondition ? null : (conditionKey ?? this.conditionKey),
      engineKey: clearEngine ? null : (engineKey ?? this.engineKey),
      plateCityKey:
          clearPlateCity ? null : (plateCityKey ?? this.plateCityKey),
      plateTypeKey:
          clearPlateType ? null : (plateTypeKey ?? this.plateTypeKey),
      engineSizeKey:
          clearEngineSize ? null : (engineSizeKey ?? this.engineSizeKey),
      cylindersKey:
          clearCylinders ? null : (cylindersKey ?? this.cylindersKey),
      importCountryKey: clearImportCountry
          ? null
          : (importCountryKey ?? this.importCountryKey),
      colorKey: clearColor ? null : (colorKey ?? this.colorKey),
      transmissionKey:
          clearTransmission ? null : (transmissionKey ?? this.transmissionKey),
      seatMaterialKey: clearSeatMaterial
          ? null
          : (seatMaterialKey ?? this.seatMaterialKey),
      selectedLocationKeys:
          selectedLocationKeys ?? this.selectedLocationKeys,
    );
  }

  AdvancedFilterState cleared({Set<String>? keepLocationKeys}) {
    return AdvancedFilterState(
      selectedLocationKeys:
          keepLocationKeys ?? selectedLocationKeys,
    );
  }
}

/// Result returned when the full-screen advanced filter is applied.
class AdvancedFilterResult {
  const AdvancedFilterResult({
    required this.filters,
    this.brand,
  });

  final AdvancedFilterState filters;
  final CarBrand? brand;
}
