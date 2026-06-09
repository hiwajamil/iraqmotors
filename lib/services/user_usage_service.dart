import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/account_type.dart';

/// Tracks per-user AI feature usage in Firestore (`user_usage` collection).
class UserUsageService {
  UserUsageService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String collection = 'user_usage';
  static const String aiAutoFillCountField = 'aiAutoFillCount';
  static const String aiAutoFillMonthField = 'aiAutoFillMonth';
  static const String lastAiAutoFillAtField = 'lastAiAutoFillAt';

  static const int individualMonthlyAiAutoFillLimit = 50;

  /// Showroom accounts are not capped (high practical limit).
  static const int showroomMonthlyAiAutoFillLimit = 100000;

  /// Returns whether [userId] may invoke AI auto-fill this month.
  Future<bool> canUseAiAutoFill({
    required String userId,
    required AccountType accountType,
  }) async {
    final limit = _monthlyLimitFor(accountType);
    if (limit >= showroomMonthlyAiAutoFillLimit) return true;

    final monthKey = _currentMonthKey();
    final doc = await _firestore.collection(collection).doc(userId).get();
    if (!doc.exists) return true;

    final data = doc.data();
    if (data == null) return true;

    final storedMonth = data[aiAutoFillMonthField] as String?;
    if (storedMonth != monthKey) return true;

    final count = _readCount(data[aiAutoFillCountField]);
    return count < limit;
  }

  /// Increments the AI auto-fill counter after a successful Gemini call.
  Future<void> recordAiAutoFillUsage(String userId) async {
    final monthKey = _currentMonthKey();
    final ref = _firestore.collection(collection).doc(userId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final data = snapshot.data();
      final storedMonth = data?[aiAutoFillMonthField] as String?;

      if (!snapshot.exists || storedMonth != monthKey) {
        transaction.set(
          ref,
          {
            aiAutoFillMonthField: monthKey,
            aiAutoFillCountField: 1,
            lastAiAutoFillAtField: FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        return;
      }

      transaction.update(ref, {
        aiAutoFillCountField: FieldValue.increment(1),
        lastAiAutoFillAtField: FieldValue.serverTimestamp(),
      });
    });
  }

  int _monthlyLimitFor(AccountType accountType) {
    return switch (accountType) {
      AccountType.showroom => showroomMonthlyAiAutoFillLimit,
      AccountType.individual => individualMonthlyAiAutoFillLimit,
    };
  }

  int _readCount(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _currentMonthKey() {
    final now = DateTime.now().toUtc();
    final month = now.month.toString().padLeft(2, '0');
    return '${now.year}-$month';
  }
}
