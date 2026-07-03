/// Maps GA4 English geo names to IQ Motors governorate keys (Kurdish script).
const Map<String, String> gaCityToGovernorate = {
  'erbil': 'هەولێر',
  'arbil': 'هەولێر',
  'hewler': 'هەولێر',
  'hawler': 'هەولێر',
  'sulaymaniyah': 'سلێمانی',
  'sulaimaniyah': 'سلێمانی',
  'suleimaniyah': 'سلێمانی',
  'as sulaymaniyah': 'سلێمانی',
  'dohuk': 'دهۆک',
  'duhok': 'دهۆک',
  'dihok': 'دهۆک',
  'kirkuk': 'کەرکووک',
  'baghdad': 'بەغداد',
  'bagdad': 'بەغداد',
};

/// Resolves a GA4 `city` dimension value to a tracked governorate key.
String? governorateFromGaCity(String gaCity) {
  final normalized = gaCity.trim().toLowerCase();
  if (normalized.isEmpty) return null;
  return gaCityToGovernorate[normalized];
}

/// Rolls up raw GA city visitor counts into governorate totals.
Map<String, int> rollupGaCityVisitors(Map<String, int> rawByGaCity) {
  final rolled = <String, int>{};
  for (final entry in rawByGaCity.entries) {
    final governorate = governorateFromGaCity(entry.key);
    if (governorate == null) continue;
    rolled[governorate] = (rolled[governorate] ?? 0) + entry.value;
  }
  return rolled;
}
