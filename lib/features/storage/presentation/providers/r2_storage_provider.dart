import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iq_motors/core/config/super_admin_config.dart';
import 'package:iq_motors/features/admin/domain/models/admin_system_config.dart';
import 'package:iq_motors/features/storage/domain/models/r2_config.dart';
import 'package:iq_motors/features/storage/data/services/r2_storage_service.dart';
import 'package:iq_motors/features/admin/presentation/providers/admin_settings_provider.dart';
import 'package:iq_motors/features/auth/presentation/providers/auth_providers.dart';

/// Resolves R2 settings from Firestore (super-admin only) with `.env` fallback.
Future<R2Config> resolveR2Config(WidgetRef ref) async {
  AdminSystemConfig? admin;
  final user = ref.read(authStateProvider).value;
  if (isSuperAdminAuthEmail(user?.email)) {
    try {
      admin = await ref.read(systemConfigProvider.future);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('systemConfig unavailable for R2, using .env fallback: $e');
      }
    }
  }
  return R2Config.resolve(admin: admin);
}

final r2StorageServiceProvider = Provider<R2StorageService>((ref) {
  final adminConfig = ref.watch(systemConfigProvider).value;
  return R2StorageService(
    config: R2Config.resolve(admin: adminConfig),
  );
});

/// Use before uploads so Firestore-backed credentials are loaded first.
Future<R2StorageService> readR2StorageServiceForUpload(WidgetRef ref) async {
  final config = await resolveR2Config(ref);
  return R2StorageService(config: config);
}
