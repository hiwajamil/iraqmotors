/// A single brand document from the `car_metadata` Firestore collection.
///
/// Hierarchy: Brand (document id) → Models (map keys) → Trims (string lists).
/// Example:
/// ```json
/// {
///   "models": {
///     "Corolla": ["L", "LE", "SE"],
///     "Camry": ["LE", "XLE"]
///   }
/// }
/// ```
class CarMetadataBrand {
  const CarMetadataBrand({
    required this.id,
    required this.models,
  });

  final String id;
  final Map<String, List<String>> models;

  List<String> get sortedModelNames {
    final names = models.keys.toList();
    names.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return names;
  }

  List<String> trimsFor(String modelName) {
    final trims = models[modelName];
    if (trims == null || trims.isEmpty) return const [];
    final sorted = List<String>.from(trims)
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return sorted;
  }

  CarMetadataBrand copyWith({
    String? id,
    Map<String, List<String>>? models,
  }) {
    return CarMetadataBrand(
      id: id ?? this.id,
      models: models ?? this.models,
    );
  }
}

/// In-memory catalog of all car metadata brands loaded for the session.
class CarMetadataCatalog {
  const CarMetadataCatalog({required this.brands});

  final Map<String, CarMetadataBrand> brands;

  static const empty = CarMetadataCatalog(brands: {});

  bool get isEmpty => brands.isEmpty;

  List<String> get sortedBrandIds {
    final ids = brands.keys.toList();
    ids.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return ids;
  }

  List<CarMetadataBrand> get sortedBrands {
    return sortedBrandIds.map((id) => brands[id]!).toList();
  }

  List<String> modelsForBrand(String? brandId) {
    if (brandId == null) return const [];
    return brands[brandId]?.sortedModelNames ?? const [];
  }

  List<String> trimsForModel(String? brandId, String? modelKey) {
    if (brandId == null || modelKey == null) return const [];
    return brands[brandId]?.trimsFor(modelKey) ?? const [];
  }

  bool hasModel(String brandId, String modelKey) =>
      brands[brandId]?.models.containsKey(modelKey) ?? false;

  /// Resolves a brand id to the exact Firestore document id (case-insensitive).
  String? resolveBrandId(String? brandId) {
    if (brandId == null) return null;
    if (brands.containsKey(brandId)) return brandId;

    final lower = brandId.toLowerCase();
    for (final id in brands.keys) {
      if (id.toLowerCase() == lower) return id;
    }
    return null;
  }

  /// Resolves a model name to the exact key stored in Firestore.
  String? resolveModelName(String brandId, String? modelName) {
    if (modelName == null) return null;
    final brand = brands[resolveBrandId(brandId) ?? brandId];
    if (brand == null) return null;
    if (brand.models.containsKey(modelName)) return modelName;

    final lower = modelName.toLowerCase();
    for (final name in brand.models.keys) {
      if (name.toLowerCase() == lower) return name;
    }
    return null;
  }
}
