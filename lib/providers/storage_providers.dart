import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/activity_log_service.dart';
import '../services/admin_database_service.dart';
import '../services/car_bid_service.dart';
import '../services/car_database_service.dart';
import '../services/car_vision_service.dart';
import '../services/cloudflare_upload_service.dart';
import '../services/storage_service.dart';
import '../services/support_ticket_service.dart';
import '../services/flagged_ads_service.dart';
import '../services/user_usage_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final activityLogServiceProvider = Provider<ActivityLogService>((ref) {
  return ActivityLogService();
});

final carDatabaseServiceProvider = Provider<CarDatabaseService>((ref) {
  return CarDatabaseService(
    activityLog: ref.watch(activityLogServiceProvider),
  );
});

/// Live home-feed listings (`status == active`).
final activeAdsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(carDatabaseServiceProvider).watchActiveAds();
});

final carBidServiceProvider = Provider<CarBidService>((ref) {
  return CarBidService();
});

final adminDatabaseServiceProvider = Provider<AdminDatabaseService>((ref) {
  return AdminDatabaseService(
    activityLog: ref.watch(activityLogServiceProvider),
  );
});

final supportTicketServiceProvider = Provider<SupportTicketService>((ref) {
  return SupportTicketService();
});

final flaggedAdsServiceProvider = Provider<FlaggedAdsService>((ref) {
  return FlaggedAdsService();
});

final userUsageServiceProvider = Provider<UserUsageService>((ref) {
  return UserUsageService();
});

final cloudflareUploadServiceProvider =
    Provider<CloudflareUploadService>((ref) {
  return CloudflareUploadService();
});

final carVisionServiceProvider = Provider<CarVisionService>((ref) {
  final service = CarVisionService(
    usageService: ref.watch(userUsageServiceProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});
