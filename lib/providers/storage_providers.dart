import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/car_database_service.dart';
import '../services/r2_storage_service.dart';
import '../services/storage_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final r2StorageServiceProvider = Provider<R2StorageService>((ref) {
  return R2StorageService();
});

final carDatabaseServiceProvider = Provider<CarDatabaseService>((ref) {
  return CarDatabaseService();
});
