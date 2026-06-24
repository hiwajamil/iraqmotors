/// A car model with display names for Kurdish, English, and Arabic.
class LocalizedCarModel {
  const LocalizedCarModel({
    required this.id,
    required this.ku,
    required this.en,
    required this.ar,
  });

  final String id;
  final String ku;
  final String en;
  final String ar;

  String labelFor(String languageCode) {
    switch (languageCode) {
      case 'en':
        return en;
      case 'ar':
        return ar;
      default:
        return ku;
    }
  }

  bool matchesKey(String key) => id == key || ku == key || en == key || ar == key;
}
