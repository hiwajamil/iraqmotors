import 'package:cloud_firestore/cloud_firestore.dart';

enum FlaggedAdStatus { pending, resolved }

extension FlaggedAdStatusX on FlaggedAdStatus {
  String get firestoreValue => switch (this) {
        FlaggedAdStatus.pending => 'pending',
        FlaggedAdStatus.resolved => 'resolved',
      };

  static FlaggedAdStatus fromFirestore(String? value) {
    return switch (value) {
      'resolved' => FlaggedAdStatus.resolved,
      _ => FlaggedAdStatus.pending,
    };
  }
}

/// A user report against a car listing in Firestore `flagged_ads`.
class FlaggedAdReport {
  const FlaggedAdReport({
    required this.id,
    required this.adId,
    required this.reason,
    required this.reportedBy,
    required this.status,
    this.reporterDisplayName,
    this.timestamp,
    this.adData,
  });

  final String id;
  final String adId;
  final String reason;
  final String reportedBy;
  final String? reporterDisplayName;
  final FlaggedAdStatus status;
  final DateTime? timestamp;
  final Map<String, dynamic>? adData;

  bool get isPending => status == FlaggedAdStatus.pending;

  factory FlaggedAdReport.fromFirestore(String id, Map<String, dynamic> data) {
    final rawTimestamp = data['timestamp'];
    DateTime? timestamp;
    if (rawTimestamp is Timestamp) {
      timestamp = rawTimestamp.toDate();
    } else if (rawTimestamp is DateTime) {
      timestamp = rawTimestamp;
    }

    return FlaggedAdReport(
      id: id,
      adId: data['adId']?.toString() ?? '',
      reason: data['reason']?.toString() ?? '',
      reportedBy: data['reportedBy']?.toString() ?? '',
      reporterDisplayName: data['reporterDisplayName']?.toString(),
      status: FlaggedAdStatusX.fromFirestore(data['status']?.toString()),
      timestamp: timestamp,
    );
  }

  FlaggedAdReport copyWith({
    String? reporterDisplayName,
    Map<String, dynamic>? adData,
  }) {
    return FlaggedAdReport(
      id: id,
      adId: adId,
      reason: reason,
      reportedBy: reportedBy,
      reporterDisplayName: reporterDisplayName ?? this.reporterDisplayName,
      status: status,
      timestamp: timestamp,
      adData: adData ?? this.adData,
    );
  }
}

/// Known reason keys stored in Firestore; free-text reasons pass through as-is.
abstract final class FlagReportReasonKeys {
  static const soldAlready = 'sold_already';
  static const wrongPrice = 'wrong_price';
  static const misleading = 'misleading';
  static const spam = 'spam';
}
