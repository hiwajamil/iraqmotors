import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/r2_config.dart';
import '../services/r2_storage_service.dart';
import 'admin_settings_provider.dart';

final r2StorageServiceProvider = Provider<R2StorageService>((ref) {
  final adminConfig = ref.watch(systemConfigProvider).value;
  return R2StorageService(
    config: R2Config.resolve(admin: adminConfig),
  );
});
