import '../l10n/app_localizations.dart';

/// Internal keys for location filter options (locale-independent storage).
abstract final class LocationKeys {
  static const allCities = 'all_cities';
  static const erbil = 'erbil';
  static const baghdad = 'baghdad';
  static const sulaymaniyah = 'sulaymaniyah';
  static const dohuk = 'dohuk';
  static const kirkuk = 'kirkuk';
  static const mosul = 'mosul';
  static const basra = 'basra';
  static const maysan = 'maysan';
  static const najaf = 'najaf';
  static const karbala = 'karbala';
  static const anbar = 'anbar';
  static const salahuddin = 'salahuddin';
  static const babylon = 'babylon';
  static const diyala = 'diyala';
  static const wasit = 'wasit';
  static const muthanna = 'muthanna';
  static const qadisiyyah = 'qadisiyyah';
  static const halabja = 'halabja';
  static const dhiQar = 'dhi_qar';

  /// Picker list order — "All Cities" first, then governorates.
  static const pickerOrder = [
    allCities,
    erbil,
    baghdad,
    sulaymaniyah,
    dohuk,
    kirkuk,
    mosul,
    basra,
    maysan,
    najaf,
    karbala,
    anbar,
    salahuddin,
    babylon,
    diyala,
    wasit,
    muthanna,
    qadisiyyah,
    halabja,
    dhiQar,
  ];

  static const governorateKeys = [
    erbil,
    baghdad,
    sulaymaniyah,
    dohuk,
    kirkuk,
    mosul,
    basra,
    maysan,
    najaf,
    karbala,
    anbar,
    salahuddin,
    babylon,
    diyala,
    wasit,
    muthanna,
    qadisiyyah,
    halabja,
    dhiQar,
  ];

  /// Default home filter — Erbil, Sulaymaniyah, and three more cities.
  static const defaultSelection = {
    erbil,
    sulaymaniyah,
    dohuk,
    kirkuk,
    baghdad,
  };

  static bool isAllCountry(Set<String> keys) =>
      keys.contains(allCities) ||
      keys.length >= governorateKeys.length;
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

  static const all = 'all';

  static const trimBase = 'trim_base';
  static const trimSport = 'trim_sport';
  static const trimLuxury = 'trim_luxury';

  static const plateTypePrivate = 'plate_private';
  static const plateTypeTemporary = 'plate_temporary';
  static const plateTypeCommercial = 'plate_commercial';

  static const engineSize1_0 = 'engine_1_0';
  static const engineSize1_5 = 'engine_1_5';
  static const engineSize2_0 = 'engine_2_0';
  static const engineSize3_0 = 'engine_3_0';

  static const cylinders4 = 'cylinders_4';
  static const cylinders6 = 'cylinders_6';
  static const cylinders8 = 'cylinders_8';

  static const importUae = 'import_uae';
  static const importUsa = 'import_usa';
  static const importEurope = 'import_europe';
  static const importGcc = 'import_gcc';
  static const importLocal = 'import_local';

  static const colorRed = 'color_red';
  static const colorBlue = 'color_blue';
  static const colorGray = 'color_gray';
  static const colorBlack = 'color_black';
  static const colorWhite = 'color_white';
  static const colorSilver = 'color_silver';
  static const colorGreen = 'color_green';

  static const transmissionAutomatic = 'transmission_automatic';
  static const transmissionManual = 'transmission_manual';

  static const seatFabric = 'seat_fabric';
  static const seatLeather = 'seat_leather';
  static const seatSemiLeather = 'seat_semi_leather';
  static const seatAlcantaraLeather = 'seat_alcantara_leather';
  static const seatAlcantara = 'seat_alcantara';
}

/// Maps filter storage keys to localized display strings.
abstract final class FilterL10n {
  static String locationLabel(AppLocalizations l10n, String key) {
    return switch (key) {
      LocationKeys.allCities => l10n.locationAllCities,
      LocationKeys.erbil => l10n.cityErbil,
      LocationKeys.baghdad => l10n.cityBaghdad,
      LocationKeys.sulaymaniyah => l10n.citySulaymaniyah,
      LocationKeys.dohuk => l10n.cityDohuk,
      LocationKeys.kirkuk => l10n.cityKirkuk,
      LocationKeys.mosul => l10n.cityMosul,
      LocationKeys.basra => l10n.cityBasra,
      LocationKeys.maysan => l10n.cityMaysan,
      LocationKeys.najaf => l10n.cityNajaf,
      LocationKeys.karbala => l10n.cityKarbala,
      LocationKeys.anbar => l10n.cityAnbar,
      LocationKeys.salahuddin => l10n.citySalahuddin,
      LocationKeys.babylon => l10n.cityBabylon,
      LocationKeys.diyala => l10n.cityDiyala,
      LocationKeys.wasit => l10n.cityWasit,
      LocationKeys.muthanna => l10n.cityMuthanna,
      LocationKeys.qadisiyyah => l10n.cityQadisiyyah,
      LocationKeys.halabja => l10n.cityHalabja,
      LocationKeys.dhiQar => l10n.cityDhiQar,
      _ => key,
    };
  }

  /// Chip / trigger label for the current multi-city selection.
  static String selectedLocationsSummary(
    AppLocalizations l10n,
    Set<String> keys,
  ) {
    if (keys.isEmpty || LocationKeys.isAllCountry(keys)) {
      return l10n.locationAllCities;
    }

    final ordered = LocationKeys.pickerOrder
        .where((k) => k != LocationKeys.allCities && keys.contains(k))
        .toList();

    if (ordered.isEmpty) {
      return l10n.locationAllCities;
    }
    if (ordered.length == 1) {
      return locationLabel(l10n, ordered.first);
    }
    if (ordered.length == 2) {
      return l10n.locationTwoCities(
        locationLabel(l10n, ordered[0]),
        locationLabel(l10n, ordered[1]),
      );
    }

    final rest = ordered.length - 2;
    return l10n.locationCitiesAndMore(
      locationLabel(l10n, ordered[0]),
      locationLabel(l10n, ordered[1]),
      _formatCount(l10n, rest),
    );
  }

  static String _formatCount(AppLocalizations l10n, int n) {
    if (l10n.localeName.startsWith('en')) {
      return n.toString();
    }
    const eastern = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((d) {
      final i = int.tryParse(d);
      return i == null ? d : eastern[i];
    }).join();
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
      FilterOptionKeys.engineEv => l10n.filterElectric,
      FilterOptionKeys.engineHybrid => l10n.engineHybrid,
      _ => l10n.enginePetrol,
    };
  }

  static String allLabel(AppLocalizations l10n) => l10n.filterAll;

  static String trimLabel(AppLocalizations l10n, String key) {
    return switch (key) {
      FilterOptionKeys.trimSport => l10n.trimSport,
      FilterOptionKeys.trimLuxury => l10n.trimLuxury,
      _ => l10n.trimBase,
    };
  }

  static String plateTypeLabel(AppLocalizations l10n, String key) {
    return switch (key) {
      FilterOptionKeys.plateTypeTemporary => l10n.plateTypeTemporary,
      FilterOptionKeys.plateTypeCommercial => l10n.plateTypeCommercial,
      _ => l10n.plateTypePrivate,
    };
  }

  static String engineSizeLabel(AppLocalizations l10n, String key) {
    return switch (key) {
      FilterOptionKeys.engineSize1_0 => '1.0L',
      FilterOptionKeys.engineSize1_5 => '1.5L',
      FilterOptionKeys.engineSize2_0 => '2.0L',
      FilterOptionKeys.engineSize3_0 => '3.0L+',
      _ => l10n.filterAll,
    };
  }

  static String cylindersLabel(AppLocalizations l10n, String key) {
    return switch (key) {
      FilterOptionKeys.cylinders6 => l10n.cylinders6,
      FilterOptionKeys.cylinders8 => l10n.cylinders8,
      _ => l10n.cylinders4,
    };
  }

  static String importCountryLabel(AppLocalizations l10n, String key) {
    return switch (key) {
      FilterOptionKeys.importUsa => l10n.importUsa,
      FilterOptionKeys.importEurope => l10n.importEurope,
      FilterOptionKeys.importGcc => l10n.importGcc,
      FilterOptionKeys.importLocal => l10n.importLocal,
      _ => l10n.importUae,
    };
  }

  static String transmissionLabel(AppLocalizations l10n, String key) {
    return switch (key) {
      FilterOptionKeys.transmissionManual => l10n.filterManual,
      _ => l10n.transmissionAutomatic,
    };
  }

  static String seatMaterialLabel(AppLocalizations l10n, String key) {
    return switch (key) {
      FilterOptionKeys.seatFabric => l10n.seatFabric,
      FilterOptionKeys.seatLeather => l10n.seatLeather,
      FilterOptionKeys.seatSemiLeather => l10n.seatSemiLeather,
      FilterOptionKeys.seatAlcantaraLeather => l10n.seatAlcantaraLeather,
      FilterOptionKeys.seatAlcantara => l10n.seatAlcantara,
      _ => l10n.filterAll,
    };
  }

  static String publisherTypeLabel(AppLocalizations l10n, String typeKey) {
    return switch (typeKey) {
      'showroom' => l10n.publisherShowroom,
      _ => l10n.publisherIndividual,
    };
  }
}
