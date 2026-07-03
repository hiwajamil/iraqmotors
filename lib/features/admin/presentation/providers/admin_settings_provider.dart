import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iq_motors/core/config/super_admin_config.dart';
import 'package:iq_motors/features/admin/data/services/analytics_service.dart';
import 'package:iq_motors/features/admin/data/services/google_analytics_remote_service.dart';
import 'package:iq_motors/features/admin/domain/models/admin_system_config.dart';
import 'package:iq_motors/features/auth/presentation/providers/auth_providers.dart';
import 'package:iq_motors/features/storage/presentation/providers/storage_providers.dart';

final googleAnalyticsRemoteServiceProvider =
    Provider<GoogleAnalyticsRemoteService>((ref) {
  return GoogleAnalyticsRemoteService();
});

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService(
    adminDatabase: ref.watch(adminDatabaseServiceProvider),
    gaRemote: ref.watch(googleAnalyticsRemoteServiceProvider),
  );
});

final systemConfigProvider = FutureProvider<AdminSystemConfig>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (!isSuperAdminAuthEmail(user?.email)) {
    return AdminSystemConfig.defaults();
  }
  return ref.read(adminDatabaseServiceProvider).fetchSystemConfig();
});
