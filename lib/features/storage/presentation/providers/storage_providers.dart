import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iq_motors/features/admin/data/services/activity_log_service.dart';
import 'package:iq_motors/features/admin/data/services/admin_database_service.dart';
import 'package:iq_motors/features/marketplace/data/services/car_bid_service.dart';
import 'package:iq_motors/features/marketplace/data/services/car_database_service.dart';
import 'package:iq_motors/features/listings/data/services/car_vision_service.dart';
import 'package:iq_motors/features/storage/data/services/cloudflare_upload_service.dart';
import 'package:iq_motors/features/storage/data/services/storage_service.dart';
import 'package:iq_motors/features/admin/data/services/support_ticket_service.dart';
import 'package:iq_motors/features/admin/data/services/flagged_ads_service.dart';
import 'package:iq_motors/features/admin/data/services/user_usage_service.dart';
import 'package:iq_motors/features/dashboard/data/services/user_message_service.dart';
import 'package:iq_motors/features/dashboard/domain/models/user_message.dart';

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

/// Live home-feed listings — admin-approved ads only (`status == active`).
final activeAdsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(carDatabaseServiceProvider).watchActiveCars().map(
        (cars) => cars.map((car) => car.toMap()).toList(),
      );
});

final carBidServiceProvider = Provider<CarBidService>((ref) {
  return CarBidService(
    messageService: ref.watch(userMessageServiceProvider),
  );
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

final userMessageServiceProvider = Provider<UserMessageService>((ref) {
  return UserMessageService();
});

/// Live inbox stream for the signed-in user.
final userInboxProvider =
    StreamProvider.family<List<UserMessage>, String>((ref, userId) {
  return ref.watch(userMessageServiceProvider).watchInbox(userId);
});

/// Unread message count for nav badges.
final userUnreadMessageCountProvider =
    StreamProvider.family<int, String>((ref, userId) {
  return ref.watch(userMessageServiceProvider).watchUnreadCount(userId);
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
