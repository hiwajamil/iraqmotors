import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iq_motors/shared/data/services/car_metadata_service.dart';
import 'package:iq_motors/shared/domain/models/car_metadata.dart';

final carMetadataServiceProvider = Provider<CarMetadataService>((ref) {
  return CarMetadataService();
});

/// Session-scoped car metadata catalog (brand → model → trim).
///
/// Kept alive so leaving Admin/filter screens does not drop the catalog;
/// [CarMetadataService] still enforces a 30-minute TTL on the session cache.
final carMetadataProvider = FutureProvider<CarMetadataCatalog>((ref) {
  ref.keepAlive();
  return ref.watch(carMetadataServiceProvider).loadCatalog();
});
