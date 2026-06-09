import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/admin_system_config.dart';
import 'storage_providers.dart';

final systemConfigProvider = FutureProvider<AdminSystemConfig>((ref) async {
  return ref.read(adminDatabaseServiceProvider).fetchSystemConfig();
});
