/// Resolves car photo URLs from a Firestore listing document map.
List<String> carImageUrlsFromAd(Map<String, dynamic> data) {
  for (final key in ['imageUrls', 'photos', 'images']) {
    final urls = _carUrlListFromField(data[key]);
    if (urls.isNotEmpty) return urls;
  }
  final single = data['imageUrl']?.toString().trim();
  if (single != null && single.isNotEmpty) return [single];
  return const [];
}

/// Primary thumbnail URL for cards and list rows.
String carPrimaryImageUrl(Map<String, dynamic> data) {
  final urls = carImageUrlsFromAd(data);
  return urls.isNotEmpty ? urls.first : '';
}

List<String> _carUrlListFromField(dynamic value) {
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isNotEmpty ? [trimmed] : const [];
  }
  if (value is List) {
    return value
        .map((e) => e?.toString().trim() ?? '')
        .where((url) => url.isNotEmpty)
        .toList();
  }
  return const [];
}
