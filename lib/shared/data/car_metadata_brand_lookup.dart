import 'package:iq_motors/shared/data/dummy_brands.dart';
import 'package:iq_motors/shared/models/car_brand.dart';

/// Resolves a metadata brand id to a [CarBrand] for filters and display.
CarBrand carBrandFromMetadataId(String brandId) {
  for (final brand in dummyBrands) {
    if (brand.id == brandId) return brand;
  }
  return CarBrand(
    id: brandId,
    nameKurdish: brandId,
    nameEnglish: brandId,
    logoUrl: '',
  );
}

/// Display label for a metadata brand id (falls back to the raw id).
String metadataBrandLabel(String brandId, String languageCode) =>
    carBrandFromMetadataId(brandId).displayName(languageCode);
