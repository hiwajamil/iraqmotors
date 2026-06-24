import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iq_motors/core/config/super_admin_config.dart';
import 'package:iq_motors/features/admin/domain/models/admin_system_config.dart';
import 'package:iq_motors/features/auth/presentation/providers/auth_providers.dart';
import 'package:iq_motors/features/storage/presentation/providers/storage_providers.dart';

final systemConfigProvider = FutureProvider<AdminSystemConfig>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (!isSuperAdminAuthEmail(user?.email)) {
    return AdminSystemConfig.defaults();
  }
  return ref.read(adminDatabaseServiceProvider).fetchSystemConfig();
});
