import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/super_admin_config.dart';
import '../models/admin_system_config.dart';
import 'auth_providers.dart';
import 'storage_providers.dart';

final systemConfigProvider = FutureProvider<AdminSystemConfig>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (!isSuperAdminAuthEmail(user?.email)) {
    return AdminSystemConfig.defaults();
  }
  return ref.read(adminDatabaseServiceProvider).fetchSystemConfig();
});
