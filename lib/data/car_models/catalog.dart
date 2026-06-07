import '../../models/localized_car_model.dart';
import 'byd_models.dart';
import 'haval_models.dart';
import 'kia_models.dart';
import 'mercedes_benz_models.dart';
import 'soueast_models.dart';
import 'toyota_models.dart';

/// Brand id ([CarBrand.id]) → localized model catalog.
const Map<String, List<LocalizedCarModel>> carModelsCatalog = {
  'toyota': toyotaModels,
  'mercedes_benz': mercedesBenzModels,
  'kia': kiaModels,
  'byd': bydModels,
  'haval': havalModels,
  'soueast': soueastModels,
};
