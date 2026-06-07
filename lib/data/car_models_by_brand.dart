import '../models/car_brand.dart';
import '../models/localized_car_model.dart';
import 'car_models/catalog.dart';

/// Car brand → model catalog for dependent filters and listing forms.
///
/// Models are stored with stable [LocalizedCarModel.id] keys; labels follow
/// the active app language (ku / en / ar).
abstract final class CarModelsByBrand {
  static const String allModelsSentinel = '__all_models__';

  /// Whether [brand] has a model list in the catalog.
  static bool hasModelsForBrand(CarBrand brand) =>
      carModelsCatalog.containsKey(brand.id);

  /// All models for [brand], or null if not catalogued yet.
  static List<LocalizedCarModel>? modelsForBrand(CarBrand? brand) {
    if (brand == null) return null;
    return carModelsCatalog[brand.id];
  }

  /// Finds a model by stable id or any localized label (legacy filter state).
  static LocalizedCarModel? findModel(CarBrand brand, String modelKey) {
    final models = carModelsCatalog[brand.id];
    if (models == null) return null;
    for (final model in models) {
      if (model.matchesKey(modelKey)) return model;
    }
    return null;
  }

  /// Canonical storage key (id) for [modelKey], or null if unknown.
  static String? canonicalModelKey(CarBrand brand, String? modelKey) {
    if (modelKey == null) return null;
    if (modelKey == allModelsSentinel) return modelKey;
    return findModel(brand, modelKey)?.id;
  }

  /// Localized display label for [modelKey] under [languageCode].
  static String? labelForModel(
    CarBrand brand,
    String modelKey,
    String languageCode,
  ) {
    return findModel(brand, modelKey)?.labelFor(languageCode);
  }

  /// Dropdown option keys: sentinel plus stable model ids.
  static List<String> modelOptionKeysForBrand(CarBrand? brand) {
    final models = modelsForBrand(brand);
    if (models == null || models.isEmpty) {
      return const [allModelsSentinel];
    }
    return [allModelsSentinel, ...models.map((m) => m.id)];
  }

  /// True when [modelKey] is valid for [brand] (id, localized name, or "all").
  static bool isValidModelSelection(CarBrand brand, String modelKey) {
    if (modelKey == allModelsSentinel) return true;
    return findModel(brand, modelKey) != null;
  }
}
