import 'package:cloud_firestore/cloud_firestore.dart';

/// A single admin audit entry stored in Firestore `activity_logs`.
class ActivityLog {
  const ActivityLog({
    required this.id,
    required this.adminId,
    required this.adminDisplayName,
    required this.action,
    required this.details,
    this.timestamp,
  });

  final String id;
  final String adminId;
  final String adminDisplayName;
  final String action;
  final String details;
  final DateTime? timestamp;

  factory ActivityLog.fromFirestore(String id, Map<String, dynamic> data) {
    final rawTimestamp = data['timestamp'];
    DateTime? timestamp;
    if (rawTimestamp is Timestamp) {
      timestamp = rawTimestamp.toDate();
    } else if (rawTimestamp is DateTime) {
      timestamp = rawTimestamp;
    }

    return ActivityLog(
      id: id,
      adminId: data['adminId']?.toString() ?? '',
      adminDisplayName: data['adminDisplayName']?.toString() ?? '',
      action: data['action']?.toString() ?? '',
      details: data['details']?.toString() ?? '',
      timestamp: timestamp,
    );
  }
}

/// Optional audit metadata passed into critical service methods.
class ActivityAuditContext {
  const ActivityAuditContext({
    required this.adminId,
    required this.action,
    required this.details,
    this.adminDisplayName,
  });

  final String adminId;
  final String action;
  final String details;
  final String? adminDisplayName;
}
