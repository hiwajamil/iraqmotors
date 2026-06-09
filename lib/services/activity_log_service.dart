import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/activity_log.dart';

class ActivityLogException implements Exception {
  ActivityLogException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Persists and reads admin audit entries in Firestore `activity_logs`.
class ActivityLogService {
  ActivityLogService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String collection = 'activity_logs';

  /// Writes a new audit entry. Failures are swallowed so the primary action
  /// is never blocked by logging issues.
  Future<void> logActivity({
    required String adminId,
    required String action,
    required String details,
    String? adminDisplayName,
  }) async {
    try {
      await _firestore.collection(collection).add({
        'adminId': adminId,
        'adminDisplayName': adminDisplayName ?? '',
        'action': action,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Best-effort audit trail.
    }
  }

  Future<void> logFromAudit(ActivityAuditContext audit) {
    return logActivity(
      adminId: audit.adminId,
      action: audit.action,
      details: audit.details,
      adminDisplayName: audit.adminDisplayName,
    );
  }

  /// Returns the most recent audit entries, newest first.
  Future<List<ActivityLog>> fetchActivityLogs({int limit = 200}) async {
    try {
      final snapshot = await _firestore
          .collection(collection)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ActivityLog.fromFirestore(doc.id, doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw ActivityLogException(
        e.message ?? 'Failed to fetch activity logs.',
      );
    } catch (e) {
      throw ActivityLogException('Failed to fetch activity logs: $e');
    }
  }
}
