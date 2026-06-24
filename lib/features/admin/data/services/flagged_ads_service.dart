import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:iq_motors/features/admin/domain/models/flagged_ad_report.dart';

class FlaggedAdsException implements Exception {
  FlaggedAdsException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Firestore access for user-submitted ad reports (`flagged_ads`).
class FlaggedAdsService {
  FlaggedAdsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String collection = 'flagged_ads';

  /// Returns pending flagged reports enriched with ad data and reporter names.
  Future<List<FlaggedAdReport>> fetchFlaggedAds() async {
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot;
      try {
        snapshot = await _firestore
            .collection(collection)
            .where('status', isEqualTo: FlaggedAdStatus.pending.firestoreValue)
            .orderBy('timestamp', descending: true)
            .get();
      } on FirebaseException catch (e) {
        if (e.code != 'failed-precondition') rethrow;
        snapshot = await _firestore
            .collection(collection)
            .where('status', isEqualTo: FlaggedAdStatus.pending.firestoreValue)
            .get();
      }

      final reports = snapshot.docs
          .map((doc) => FlaggedAdReport.fromFirestore(doc.id, doc.data()))
          .toList();

      reports.sort((a, b) {
        final aTime = a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

      return _enrichReports(reports);
    } on FirebaseException catch (e) {
      throw FlaggedAdsException(
        e.message ?? 'Failed to fetch flagged ads.',
      );
    } catch (e) {
      throw FlaggedAdsException('Failed to fetch flagged ads: $e');
    }
  }

  /// Marks a report as resolved without deleting the ad.
  Future<void> resolveFlaggedAd({required String reportId}) async {
    try {
      await _firestore.collection(collection).doc(reportId).update({
        'status': FlaggedAdStatus.resolved.firestoreValue,
        'resolvedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw FlaggedAdsException(
        e.message ?? 'Failed to resolve flagged ad.',
      );
    } catch (e) {
      throw FlaggedAdsException('Failed to resolve flagged ad: $e');
    }
  }

  /// Submits a new flag report (user-facing flow).
  Future<void> reportAd({
    required String adId,
    required String reason,
    required String reportedBy,
  }) async {
    final trimmedReason = reason.trim();
    if (trimmedReason.isEmpty) {
      throw FlaggedAdsException('Report reason cannot be empty.');
    }

    try {
      await _firestore.collection(collection).add({
        'adId': adId,
        'reason': trimmedReason,
        'reportedBy': reportedBy,
        'status': FlaggedAdStatus.pending.firestoreValue,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw FlaggedAdsException(
        e.message ?? 'Failed to submit report.',
      );
    } catch (e) {
      throw FlaggedAdsException('Failed to submit report: $e');
    }
  }

  Future<List<FlaggedAdReport>> _enrichReports(
    List<FlaggedAdReport> reports,
  ) async {
    if (reports.isEmpty) return reports;

    final adIds = reports.map((r) => r.adId).where((id) => id.isNotEmpty).toSet();
    final reporterIds =
        reports.map((r) => r.reportedBy).where((id) => id.isNotEmpty).toSet();

    final adDocs = await Future.wait(
      adIds.map((id) => _firestore.collection('cars').doc(id).get()),
    );
    final adMap = {
      for (final doc in adDocs)
        if (doc.exists) doc.id: {'id': doc.id, ...?doc.data()},
    };

    final reporterDocs = await Future.wait(
      reporterIds.map((id) => _firestore.collection('users').doc(id).get()),
    );
    final reporterNames = <String, String>{};
    for (final doc in reporterDocs) {
      if (!doc.exists) continue;
      final name = doc.data()?['displayName']?.toString().trim() ?? '';
      if (name.isNotEmpty) reporterNames[doc.id] = name;
    }

    return reports
        .map(
          (report) => report.copyWith(
            adData: adMap[report.adId],
            reporterDisplayName: report.reporterDisplayName ??
                reporterNames[report.reportedBy],
          ),
        )
        .toList();
  }
}
