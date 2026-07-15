import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iq_motors/shared/data/services/car_metadata_service.dart';
import 'package:iq_motors/shared/domain/models/car_metadata.dart';

final carMetadataServiceProvider = Provider<CarMetadataService>((ref) {
  return CarMetadataService();
});

/// Session-scoped car metadata catalog (brand → model → trim).
final carMetadataProvider = FutureProvider<CarMetadataCatalog>((ref) {
  return ref.watch(carMetadataServiceProvider).loadCatalog();
});
