import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/activity_log.dart';
import '../providers/auth_providers.dart';

/// Builds audit context for the currently signed-in super admin.
ActivityAuditContext? buildAdminAudit(
  WidgetRef ref, {
  required String action,
  required String details,
}) {
  final user = ref.read(authStateProvider).value;
  if (user == null) return null;

  final profile = ref.read(userProfileProvider).value;
  final displayName = profile?.displayName.trim();
  final fallback = user.email?.trim();

  return ActivityAuditContext(
    adminId: user.uid,
    adminDisplayName: (displayName != null && displayName.isNotEmpty)
        ? displayName
        : fallback,
    action: action,
    details: details,
  );
}
