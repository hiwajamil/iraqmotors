import '../l10n/app_localizations.dart';

/// Internal keys for location filter options (locale-independent storage).
abstract final class LocationKeys {
  static const defaultRegion = 'default_region';
  static const erbil = 'erbil';
  static const sulaymaniyah = 'sulaymaniyah';
  static const dohuk = 'dohuk';
  static const kirkuk = 'kirkuk';
  static const allCities = 'all_cities';

  static const all = [
    defaultRegion,
    erbil,
    sulaymaniyah,
    dohuk,
    kirkuk,
    allCities,
  ];
}

abstract final class FilterOptionKeys {
  static const allModels = 'all_models';
  static const camry = 'camry';
  static const landCruiser = 'land_cruiser';
  static const patrol = 'patrol';
  static const escalade = 'escalade';

  static const allYears = 'all_years';

  static const allMileages = 'all_mileages';
  static const mileage0 = 'mileage_0';
  static const mileage10k = 'mileage_10k';
  static const mileage50k = 'mileage_50k';
  static const mileage100k = 'mileage_100k';
  static const mileage100kPlus = 'mileage_100k_plus';

  static const allPrices = 'all_prices';
  static const price20k = 'price_20k';
  static const price50k = 'price_50k';
  static const price100k = 'price_100k';
  static const price100kPlus = 'price_100k_plus';

  static const conditionNew = 'condition_new';
  static const conditionUsed = 'condition_used';

  static const enginePetrol = 'engine_petrol';
  static const engineEv = 'engine_ev';
  static const engineHybrid = 'engine_hybrid';
}

/// Maps filter storage keys to localized display strings.
abstract final class FilterL10n {
  static String locationLabel(AppLocalizations l10n, String key) {
    return switch (key) {
      LocationKeys.erbil => l10n.cityErbil,
      LocationKeys.sulaymaniyah => l10n.citySulaymaniyah,
      LocationKeys.dohuk => l10n.cityDohuk,
      LocationKeys.kirkuk => l10n.cityKirkuk,
      LocationKeys.allCities => l10n.locationAllCities,
      _ => l10n.locationDefaultRegion,
    };
  }

  static String modelLabel(AppLocalizations l10n, String key) {
    return switch (key) {
      FilterOptionKeys.camry => l10n.modelCamry,
      FilterOptionKeys.landCruiser => l10n.modelLandCruiser,
      FilterOptionKeys.patrol => l10n.modelPatrol,
      FilterOptionKeys.escalade => 'Escalade',
      _ => l10n.filterAllModels,
    };
  }

  static String mileageLabel(AppLocalizations l10n, String key) {
    return switch (key) {
      FilterOptionKeys.mileage0 => l10n.mileage0,
      FilterOptionKeys.mileage10k => l10n.mileage10k,
      FilterOptionKeys.mileage50k => l10n.mileage50k,
      FilterOptionKeys.mileage100k => l10n.mileage100k,
      FilterOptionKeys.mileage100kPlus => l10n.mileage100kPlus,
      _ => l10n.filterAllMileages,
    };
  }

  static String priceLabel(AppLocalizations l10n, String key) {
    return switch (key) {
      FilterOptionKeys.price20k => l10n.price20k,
      FilterOptionKeys.price50k => l10n.price50k,
      FilterOptionKeys.price100k => l10n.price100k,
      FilterOptionKeys.price100kPlus => l10n.price100kPlus,
      _ => l10n.filterAllPrices,
    };
  }

  static String conditionLabel(AppLocalizations l10n, String key) {
    return switch (key) {
      FilterOptionKeys.conditionUsed => l10n.conditionUsed,
      _ => l10n.conditionNew,
    };
  }

  static String engineLabel(AppLocalizations l10n, String key) {
    return switch (key) {
      FilterOptionKeys.engineEv => 'EV',
      FilterOptionKeys.engineHybrid => l10n.engineHybrid,
      _ => l10n.enginePetrol,
    };
  }

  static String publisherTypeLabel(AppLocalizations l10n, String typeKey) {
    return switch (typeKey) {
      'showroom' => l10n.publisherShowroom,
      _ => l10n.publisherIndividual,
    };
  }
}
