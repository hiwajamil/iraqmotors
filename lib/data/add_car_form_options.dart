import 'package:flutter/material.dart';

import '../core/filter_l10n.dart';
import '../l10n/app_localizations.dart';
import 'add_car_option_keys.dart';

/// Static option lists for the add-car wizard steps.
abstract final class AddCarFormOptions {
  static const Color aiAccentFill = Color(0xFFEBE0FF);
  static const Color aiAccentText = Color(0xFF5E3FD9);
  static const Color fieldFill = Color(0xFFE5E5EA);

  static const List<String> colorKeys = [
    FilterOptionKeys.colorBlack,
    FilterOptionKeys.colorWhite,
    FilterOptionKeys.colorSilver,
    FilterOptionKeys.colorGray,
    FilterOptionKeys.colorRed,
    FilterOptionKeys.colorBlue,
    FilterOptionKeys.colorGreen,
  ];

  static const List<String> years = [
    '2026',
    '2025',
    '2024',
    '2023',
    '2022',
    '2021',
    '2020',
    '2019',
    '2018',
    '2017',
    '2016',
    '2015',
    '2014',
    '2013',
    '2012',
    '2011',
    '2010',
    '2009',
    '2008',
    '2007',
    '2006',
    '2005',
    '2004',
    '2003',
    '2002',
    '2001',
    '2000',
  ];

  static const List<String> trims = [
    'SR',
    'SE',
    'LE',
    'XLE',
    'Limited',
    'Sport',
    'Luxury',
    'Base',
  ];

  static const List<String> plateTypeChipKeys = [
    FilterOptionKeys.plateTypePrivate,
    FilterOptionKeys.plateTypeTemporary,
    AddCarOptionKeys.plateCargo,
  ];

  static const List<String> plateTypeOtherKeys = [
    FilterOptionKeys.plateTypeCommercial,
    AddCarOptionKeys.plateGovernment,
    AddCarOptionKeys.plateDiplomatic,
    AddCarOptionKeys.plateTaxi,
  ];

  static const List<String> plateCityChipKeys = [
    LocationKeys.erbil,
    LocationKeys.maysan,
    LocationKeys.sulaymaniyah,
    LocationKeys.dohuk,
    LocationKeys.kirkuk,
    LocationKeys.baghdad,
  ];

  static List<String> get plateCityOtherKeys => LocationKeys.governorateKeys
      .where((key) => !plateCityChipKeys.contains(key))
      .toList();

  static const List<String> fuelChipKeys = [
    FilterOptionKeys.enginePetrol,
    FilterOptionKeys.engineHybrid,
    FilterOptionKeys.engineEv,
    AddCarOptionKeys.fuelPlugInHybrid,
    AddCarOptionKeys.fuelLpg,
    AddCarOptionKeys.fuelCng,
  ];

  static const List<String> mileageUnits = [
    AddCarOptionKeys.mileageUnitKm,
    AddCarOptionKeys.mileageUnitMi,
  ];

  static const String defaultFuelKey = FilterOptionKeys.enginePetrol;

  static const List<String> importCountryChipKeys = [
    FilterOptionKeys.importUsa,
    FilterOptionKeys.importGcc,
    FilterOptionKeys.importLocal,
  ];

  static const List<String> importCountryOtherKeys = [
    FilterOptionKeys.importEurope,
    FilterOptionKeys.importUae,
  ];

  static const List<String> transmissionChipKeys = [
    FilterOptionKeys.transmissionAutomatic,
    FilterOptionKeys.transmissionManual,
  ];

  static const List<String> cylinderChipKeys = [
    FilterOptionKeys.cylinders6,
    FilterOptionKeys.cylinders4,
  ];

  static const List<String> engineSizeChipKeys = [
    AddCarOptionKeys.engineSize20T,
    AddCarOptionKeys.engineSize25,
    AddCarOptionKeys.engineSize20,
    AddCarOptionKeys.engineSize35,
    AddCarOptionKeys.engineSize24,
  ];

  static const List<String> seatMaterialKeys = [
    FilterOptionKeys.seatFabric,
    FilterOptionKeys.seatLeather,
    FilterOptionKeys.seatSemiLeather,
    FilterOptionKeys.seatAlcantara,
    FilterOptionKeys.seatAlcantaraLeather,
  ];

  static const List<String> seatCountKeys = [
    AddCarOptionKeys.seats9,
    AddCarOptionKeys.seats8,
    AddCarOptionKeys.seats7,
    AddCarOptionKeys.seats6,
    AddCarOptionKeys.seats5,
    AddCarOptionKeys.seats4,
    AddCarOptionKeys.seats2,
    AddCarOptionKeys.seats10Plus,
  ];

  static const List<String> conditionChipKeys = [
    AddCarOptionKeys.conditionCleanTitle,
    AddCarOptionKeys.conditionNoPaint,
    AddCarOptionKeys.conditionDamage1,
    AddCarOptionKeys.conditionDamage2,
    AddCarOptionKeys.conditionDamage3,
    AddCarOptionKeys.conditionDamage4,
    AddCarOptionKeys.conditionDamage5,
    AddCarOptionKeys.conditionDamage6,
  ];

  static const List<String> featureKeys = [
    AddCarOptionKeys.featureRearCamera,
    AddCarOptionKeys.featureParkingBrake,
    AddCarOptionKeys.featureSensitive,
    AddCarOptionKeys.featureSeatHeater,
    AddCarOptionKeys.featureSunroof,
    AddCarOptionKeys.featureHorn,
    AddCarOptionKeys.featureSpeedSign,
    AddCarOptionKeys.featureElectricMirror,
    AddCarOptionKeys.featureScreen,
    AddCarOptionKeys.featureRadarMirror,
    AddCarOptionKeys.featureSmartKey,
    AddCarOptionKeys.featureElectricSeat,
    AddCarOptionKeys.featureSpeaker8,
    AddCarOptionKeys.featureXenonLight,
    AddCarOptionKeys.featureCruiseControl,
    AddCarOptionKeys.featureSteeringHeater,
    AddCarOptionKeys.featureAppleCarplay,
    AddCarOptionKeys.featurePanoramicRoof,
    AddCarOptionKeys.featureAbs,
    AddCarOptionKeys.featureAwd,
    AddCarOptionKeys.featureRadar,
    AddCarOptionKeys.featureWirelessCharger,
    AddCarOptionKeys.featureAntiTheft,
    AddCarOptionKeys.featureAutoHeadlight,
    AddCarOptionKeys.featureTirePressure,
    AddCarOptionKeys.featureDriverAttention,
  ];

  static const List<String> currencyKeys = [
    AddCarOptionKeys.currencyIqd,
    AddCarOptionKeys.currencyUsd,
  ];

  static const String defaultCurrencyKey = AddCarOptionKeys.currencyUsd;

  static bool isDamageCondition(String? key) {
    if (key == null) return false;
    return key.startsWith('condition_damage_');
  }

  static Color swatchForKey(String key) {
    return switch (key) {
      FilterOptionKeys.colorRed => const Color(0xFFE53935),
      FilterOptionKeys.colorBlue => const Color(0xFF1E88E5),
      FilterOptionKeys.colorGray => const Color(0xFF9E9E9E),
      FilterOptionKeys.colorBlack => const Color(0xFF212121),
      FilterOptionKeys.colorWhite => const Color(0xFFFAFAFA),
      FilterOptionKeys.colorSilver => const Color(0xFFBDBDBD),
      FilterOptionKeys.colorGreen => const Color(0xFF43A047),
      _ => const Color(0xFF9E9E9E),
    };
  }

  static String colorLabel(String key, String languageCode) {
    return switch (key) {
      FilterOptionKeys.colorBlack => switch (languageCode) {
          'en' => 'Black',
          'ar' => 'أسود',
          _ => 'ڕەش',
        },
      FilterOptionKeys.colorWhite => switch (languageCode) {
          'en' => 'White',
          'ar' => 'أبيض',
          _ => 'سپی',
        },
      FilterOptionKeys.colorSilver => switch (languageCode) {
          'en' => 'Silver',
          'ar' => 'فضي',
          _ => 'زیو',
        },
      FilterOptionKeys.colorGray => switch (languageCode) {
          'en' => 'Gray',
          'ar' => 'رمادي',
          _ => 'خۆڵەمێشی',
        },
      FilterOptionKeys.colorRed => switch (languageCode) {
          'en' => 'Red',
          'ar' => 'أحمر',
          _ => 'سور',
        },
      FilterOptionKeys.colorBlue => switch (languageCode) {
          'en' => 'Blue',
          'ar' => 'أزرق',
          _ => 'شین',
        },
      FilterOptionKeys.colorGreen => switch (languageCode) {
          'en' => 'Green',
          'ar' => 'أخضر',
          _ => 'سەوز',
        },
      _ => key,
    };
  }

  static String plateTypeLabel(AppLocalizations l10n, String key) {
    return switch (key) {
      AddCarOptionKeys.plateCargo => switch (l10n.localeName.split('_').first) {
          'en' => 'Cargo',
          'ar' => 'حمولة',
          _ => 'بار هەڵگر',
        },
      AddCarOptionKeys.plateGovernment => switch (l10n.localeName.split('_').first) {
          'en' => 'Government',
          'ar' => 'حكومي',
          _ => 'حکومی',
        },
      AddCarOptionKeys.plateDiplomatic => switch (l10n.localeName.split('_').first) {
          'en' => 'Diplomatic',
          'ar' => 'دبلوماسي',
          _ => 'دیپلۆمات',
        },
      AddCarOptionKeys.plateTaxi => switch (l10n.localeName.split('_').first) {
          'en' => 'Taxi',
          'ar' => 'أجرة',
          _ => 'تاکسی',
        },
      _ => FilterL10n.plateTypeLabel(l10n, key),
    };
  }

  static String plateCityLabel(AppLocalizations l10n, String key) {
    return FilterL10n.locationLabel(l10n, key);
  }

  static String fuelLabel(AppLocalizations l10n, String key) {
    return switch (key) {
      FilterOptionKeys.engineHybrid => l10n.engineHybrid,
      FilterOptionKeys.engineEv => l10n.filterElectric,
      AddCarOptionKeys.fuelPlugInHybrid =>
        switch (l10n.localeName.split('_').first) {
          'en' => 'Plug-in Hybrid',
          'ar' => 'هجين قابل للشحن',
          _ => 'هایبریدی پڵەگین',
        },
      AddCarOptionKeys.fuelLpg => switch (l10n.localeName.split('_').first) {
          'en' => 'LPG',
          'ar' => 'غاز',
          _ => 'غاز',
        },
      AddCarOptionKeys.fuelCng => switch (l10n.localeName.split('_').first) {
          'en' => 'CNG',
          'ar' => 'غاز طبيعي',
          _ => 'گاز',
        },
      _ => l10n.enginePetrol,
    };
  }

  static String mileageUnitLabel(AppLocalizations l10n, String key) {
    return switch (key) {
      AddCarOptionKeys.mileageUnitMi => switch (l10n.localeName.split('_').first) {
          'en' => 'mi',
          'ar' => 'ميل',
          _ => 'میل',
        },
      _ => switch (l10n.localeName.split('_').first) {
          'en' => 'km',
          'ar' => 'كم',
          _ => 'كم',
        },
    };
  }

  static String importCountryLabel(AppLocalizations l10n, String key) {
    final locale = l10n.localeName.split('_').first;
    return switch (key) {
      FilterOptionKeys.importUsa => switch (locale) {
          'en' => 'American',
          'ar' => 'أمريكي',
          _ => 'ئەمەریکی',
        },
      FilterOptionKeys.importGcc => switch (locale) {
          'en' => 'Gulf',
          'ar' => 'خليجي',
          _ => 'خەلیجی',
        },
      FilterOptionKeys.importLocal => switch (locale) {
          'en' => 'Iraqi',
          'ar' => 'عراقي',
          _ => 'عێراقی',
        },
      _ => FilterL10n.importCountryLabel(l10n, key),
    };
  }

  static String transmissionLabel(AppLocalizations l10n, String key) {
    return FilterL10n.transmissionLabel(l10n, key);
  }

  static String cylindersLabel(AppLocalizations l10n, String key) {
    return FilterL10n.cylindersLabel(l10n, key);
  }

  static String engineSizeLabel(AppLocalizations l10n, String key) {
    return switch (key) {
      AddCarOptionKeys.engineSize20T => '2.0T',
      AddCarOptionKeys.engineSize25 => '2.5',
      AddCarOptionKeys.engineSize20 => '2.0',
      AddCarOptionKeys.engineSize35 => '3.5',
      AddCarOptionKeys.engineSize24 => '2.4',
      FilterOptionKeys.engineSize1_0 => '1.0',
      FilterOptionKeys.engineSize1_5 => '1.5',
      FilterOptionKeys.engineSize3_0 => '3.0+',
      _ => key,
    };
  }

  static String seatMaterialLabel(AppLocalizations l10n, String key) {
    return FilterL10n.seatMaterialLabel(l10n, key);
  }

  static String seatCountLabel(AppLocalizations l10n, String key) {
    return switch (key) {
      AddCarOptionKeys.seats10Plus => '+10',
      AddCarOptionKeys.seats9 => '9',
      AddCarOptionKeys.seats8 => '8',
      AddCarOptionKeys.seats7 => '7',
      AddCarOptionKeys.seats6 => '6',
      AddCarOptionKeys.seats5 => '5',
      AddCarOptionKeys.seats4 => '4',
      AddCarOptionKeys.seats2 => '2',
      _ => key,
    };
  }

  static String conditionLabel(AppLocalizations l10n, String key) {
    final locale = l10n.localeName.split('_').first;
    return switch (key) {
      AddCarOptionKeys.conditionCleanTitle => switch (locale) {
          'en' => 'Clean Title',
          'ar' => 'عنوان نظيف',
          _ => 'کلین تایتل',
        },
      AddCarOptionKeys.conditionNoPaint => switch (locale) {
          'en' => 'No Paint',
          'ar' => 'بدون طلاء',
          _ => 'بێ بۆیاغ',
        },
      AddCarOptionKeys.conditionDamage1 => switch (locale) {
          'en' => '1 Panel',
          'ar' => 'قطعة واحدة',
          _ => '1 پارچە',
        },
      AddCarOptionKeys.conditionDamage2 => switch (locale) {
          'en' => '2 Panels',
          'ar' => 'قطعتان',
          _ => '2 پارچە',
        },
      AddCarOptionKeys.conditionDamage3 => switch (locale) {
          'en' => '3 Panels',
          'ar' => '3 قطع',
          _ => '3 پارچە',
        },
      AddCarOptionKeys.conditionDamage4 => switch (locale) {
          'en' => '4 Panels',
          'ar' => '4 قطع',
          _ => '4 پارچە',
        },
      AddCarOptionKeys.conditionDamage5 => switch (locale) {
          'en' => '5 Panels',
          'ar' => '5 قطع',
          _ => '5 پارچە',
        },
      AddCarOptionKeys.conditionDamage6 => switch (locale) {
          'en' => '6 Panels',
          'ar' => '6 قطع',
          _ => '6 پارچە',
        },
      _ => key,
    };
  }

  static String featureLabel(AppLocalizations l10n, String key) {
    final locale = l10n.localeName.split('_').first;
    return switch (key) {
      AddCarOptionKeys.featureRearCamera => switch (locale) {
          'en' => 'Rear Camera',
          'ar' => 'كاميرا خلفية',
          _ => 'کامێرای دواوە',
        },
      AddCarOptionKeys.featureParkingBrake => switch (locale) {
          'en' => 'Parking Brake',
          'ar' => 'فرامل يد',
          _ => 'ڕاگری نشێوی',
        },
      AddCarOptionKeys.featureSensitive => switch (locale) {
          'en' => 'Sensitive',
          'ar' => 'حساس',
          _ => 'حەساس',
        },
      AddCarOptionKeys.featureSeatHeater => switch (locale) {
          'en' => 'Seat Heater',
          'ar' => 'تدفئة المقاعد',
          _ => 'گەرمکەرەوەی کوشن',
        },
      AddCarOptionKeys.featureSunroof => switch (locale) {
          'en' => 'Sunroof',
          'ar' => 'فتحة سقف',
          _ => 'سلاید',
        },
      AddCarOptionKeys.featureHorn => switch (locale) {
          'en' => 'Horn',
          'ar' => 'بوق',
          _ => 'بەسمە',
        },
      AddCarOptionKeys.featureSpeedSign => switch (locale) {
          'en' => 'Speed Sign Detection',
          'ar' => 'كشف إشارات السرعة',
          _ => 'دیاریکرنی خێرایی',
        },
      AddCarOptionKeys.featureElectricMirror => switch (locale) {
          'en' => 'Power Side Mirrors',
          'ar' => 'مرايا جانبية كهربائية',
          _ => 'ئاوێنەی لاتەنیشتی کارەبایی',
        },
      AddCarOptionKeys.featureScreen => switch (locale) {
          'en' => 'Screen',
          'ar' => 'شاشة',
          _ => 'شاشە',
        },
      AddCarOptionKeys.featureRadarMirror => switch (locale) {
          'en' => 'Radar Mirror',
          'ar' => 'مرآة رادار',
          _ => 'ئاوێنەی ڕادار',
        },
      AddCarOptionKeys.featureSmartKey => switch (locale) {
          'en' => 'Smart Key',
          'ar' => 'مفتاح ذكي',
          _ => 'سیستەمی کلیلی زیرەک',
        },
      AddCarOptionKeys.featureElectricSeat => switch (locale) {
          'en' => 'Power Seats',
          'ar' => 'مقاعد كهربائية',
          _ => 'کورسی کارەبایی',
        },
      AddCarOptionKeys.featureSpeaker8 => switch (locale) {
          'en' => '8 Speakers',
          'ar' => '8 مكبرات',
          _ => '8 پەڕەشووت',
        },
      AddCarOptionKeys.featureXenonLight => switch (locale) {
          'en' => 'Xenon Headlights',
          'ar' => 'مصابيح زينون',
          _ => 'لایتی پێشەوەی زینۆن',
        },
      AddCarOptionKeys.featureCruiseControl => switch (locale) {
          'en' => 'Cruise Control',
          'ar' => 'مثبت سرعة',
          _ => 'کۆنترۆڵکردنی خزان',
        },
      AddCarOptionKeys.featureSteeringHeater => switch (locale) {
          'en' => 'Heated Steering',
          'ar' => 'تدفئة المقود',
          _ => 'سوکان هیتەر',
        },
      AddCarOptionKeys.featureAppleCarplay => switch (locale) {
          'en' => 'Apple CarPlay',
          'ar' => 'Apple CarPlay',
          _ => 'ئەپڵ کارپلەی',
        },
      AddCarOptionKeys.featurePanoramicRoof => switch (locale) {
          'en' => 'Panoramic Roof',
          'ar' => 'سقف بانورامي',
          _ => 'شەغال',
        },
      AddCarOptionKeys.featureAbs => 'ABS',
      AddCarOptionKeys.featureAwd => 'AWD',
      AddCarOptionKeys.featureRadar => switch (locale) {
          'en' => 'Radar',
          'ar' => 'رادار',
          _ => 'ڕادار',
        },
      AddCarOptionKeys.featureWirelessCharger => switch (locale) {
          'en' => 'Wireless Charger',
          'ar' => 'شاحن لاسلكي',
          _ => 'بارگاویکەرەوەی بێتەل',
        },
      AddCarOptionKeys.featureAntiTheft => switch (locale) {
          'en' => 'Anti-Theft',
          'ar' => 'مضاد للسرقة',
          _ => 'سیستەمی دژە دزی',
        },
      AddCarOptionKeys.featureAutoHeadlight => switch (locale) {
          'en' => 'Auto Headlights',
          'ar' => 'إضاءة أمامية تلقائية',
          _ => 'فوول لایتی ئۆتۆماتیک',
        },
      AddCarOptionKeys.featureTirePressure => switch (locale) {
          'en' => 'Tire Pressure Sensor',
          'ar' => 'حساس ضغط الإطارات',
          _ => 'هەستەوەری پەستانی تایە',
        },
      AddCarOptionKeys.featureDriverAttention => switch (locale) {
          'en' => 'Driver Attention Alert',
          'ar' => 'تنبيه انتباه السائق',
          _ => 'ئاگادارکردنەوەی سەرنجی شۆفێر',
        },
      _ => key,
    };
  }

  static String currencyLabel(AppLocalizations l10n, String key) {
    final locale = l10n.localeName.split('_').first;
    return switch (key) {
      AddCarOptionKeys.currencyIqd => switch (locale) {
          'en' => 'IQD (Iraqi Dinar)',
          'ar' => 'د.ع (دينار عراقي)',
          _ => 'د.ع (دیناری عێراقی)',
        },
      _ => switch (locale) {
          'en' => r'$ (US Dollar)',
          'ar' => r'$ (دولار)',
          _ => r'$ (دۆلار)',
        },
    };
  }

  static String currencySymbol(String key) {
    return switch (key) {
      AddCarOptionKeys.currencyIqd => 'د.ع',
      _ => r'$',
    };
  }

  static const List<String> packageKeys = [
    AddCarOptionKeys.packageBoost,
    AddCarOptionKeys.packageSuperBoost,
  ];

  static const List<String> paymentMethodKeys = [
    AddCarOptionKeys.paymentDebitCard,
    AddCarOptionKeys.paymentEWallet,
    AddCarOptionKeys.paymentFib,
  ];
}
