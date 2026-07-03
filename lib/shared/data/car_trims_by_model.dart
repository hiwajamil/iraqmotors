/// Trim / variant options keyed by catalog [modelKey] (e.g. `toyota_camry`).
abstract final class CarTrimsByModel {
  static const List<String> _toyotaSedanTrims = [
    'SR',
    'SE',
    'LE',
    'XLE',
    'Limited',
  ];

  static const List<String> _toyotaSuvTrims = [
    'SR',
    'SE',
    'LE',
    'XLE',
    'Limited',
    'Platinum',
  ];

  static const List<String> _toyotaPickupTrims = [
    'SR',
    'SR5',
    'TRD',
    'Limited',
  ];

  static const Map<String, List<String>> _trimsByModelId = {
    'toyota_camry': _toyotaSedanTrims,
    'toyota_corolla': ['L', 'LE', 'SE', 'XLE', 'XSE'],
    'toyota_corolla_cross': ['L', 'LE', 'SE', 'XLE', 'XSE'],
    'toyota_corolla_hatchback': ['SE', 'XSE'],
    'toyota_crown': ['XLE', 'Limited', 'Platinum'],
    'toyota_avalon': ['XLE', 'Limited', 'Touring'],
    'toyota_yaris': ['L', 'LE', 'SE', 'XLE'],
    'toyota_prius': ['LE', 'XLE', 'Limited'],
    'toyota_rav4': _toyotaSuvTrims,
    'toyota_highlander': _toyotaSuvTrims,
    'toyota_grand_highlander': _toyotaSuvTrims,
    'toyota_4runner': ['SR5', 'TRD Off-Road', 'TRD Pro', 'Limited'],
    'toyota_land_cruiser': ['GXR', 'VXR', 'GR Sport', 'Heritage Edition'],
    'toyota_land_cruiser_prado': ['TX', 'TXL', 'VX', 'VXL', 'Adventure'],
    'toyota_hilux': _toyotaPickupTrims,
    'toyota_tacoma': _toyotaPickupTrims,
    'toyota_tundra': _toyotaPickupTrims,
    'toyota_fortuner': ['GX', 'GXR', 'VXR'],
    'toyota_sequoia': ['SR5', 'Limited', 'Platinum', 'TRD Pro'],
    'toyota_sienna': ['LE', 'XLE', 'XSE', 'Limited', 'Platinum'],
    'toyota_venza': ['LE', 'XLE', 'Limited'],
    'toyota_chr': ['LE', 'XLE', 'Limited'],
    'toyota_fj_cruiser': ['Base', 'Trail Teams'],
    'lexus_rx': ['RX 350', 'RX 350h', 'RX 500h', 'RX 450h+'],
    'lexus_es': ['ES 250', 'ES 300h', 'ES 350'],
    'lexus_is': ['IS 300', 'IS 350', 'IS 500'],
    'lexus_lx': ['LX 600', 'LX 600 Ultra Luxury'],
    'lexus_gx': ['GX 460', 'GX 550'],
    'hyundai_sonata': ['SE', 'SEL', 'N Line', 'Limited'],
    'hyundai_tucson': ['SE', 'SEL', 'N Line', 'Limited'],
    'hyundai_santa_fe': ['SE', 'SEL', 'XRT', 'Limited', 'Calligraphy'],
    'kia_k5': ['LXS', 'GT-Line', 'EX', 'GT'],
    'kia_sportage': ['LX', 'EX', 'SX', 'X-Line'],
    'kia_sorento': ['LX', 'EX', 'SX', 'SX Prestige'],
    'bmw_series_3': ['320i', '330i', '330e', 'M340i'],
    'bmw_series_5': ['530i', '540i', '530e', 'M550i'],
    'bmw_x5': ['xDrive40i', 'xDrive50e', 'M60i'],
    'mercedes_benz_mb_c_class': ['C 200', 'C 300', 'AMG C 43'],
    'mercedes_benz_mb_e_class': ['E 200', 'E 300', 'E 450', 'AMG E 53'],
    'mercedes_benz_mb_glc': ['GLC 200', 'GLC 300', 'AMG GLC 43'],
  };

  /// Trims for the selected brand + model, or empty when none are catalogued.
  static List<String> trimsFor(String? brandId, String? modelKey) {
    if (modelKey == null || modelKey.isEmpty) return const [];

    final direct = _trimsByModelId[modelKey];
    if (direct != null) return direct;

    if (brandId != null && brandId.isNotEmpty) {
      final prefixed = _trimsByModelId['${brandId}_$modelKey'];
      if (prefixed != null) return prefixed;
    }

    return const [];
  }

  static bool hasTrims(String? brandId, String? modelKey) =>
      trimsFor(brandId, modelKey).isNotEmpty;
}
