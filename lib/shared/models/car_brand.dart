/// Automotive brand shown in search and listing filters.
class CarBrand {
  const CarBrand({
    required this.id,
    required this.nameKurdish,
    required this.nameEnglish,
    required this.logoUrl,
  });

  final String id;
  final String nameKurdish;
  final String nameEnglish;
  final String logoUrl;

  bool matchesQuery(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return true;
    final lower = trimmed.toLowerCase();
    return id.contains(lower) ||
        nameEnglish.toLowerCase().contains(lower) ||
        nameKurdish.contains(trimmed);
  }

  /// Returns the brand name for the active app language.
  String displayName(String languageCode) {
    switch (languageCode) {
      case 'en':
      case 'ar':
        return nameEnglish;
      default:
        return nameKurdish;
    }
  }
}
