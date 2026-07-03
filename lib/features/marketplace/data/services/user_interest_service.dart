import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:iq_motors/features/marketplace/domain/models/user_car_interest.dart';

/// Persists recent brand/model interests in [SharedPreferences] (no Firestore).
class UserInterestService {
  static const String _storageKey = 'user_car_interests';
  static const int maxInterests = 3;

  Future<List<UserCarInterest>> getInterests() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];

      return decoded
          .whereType<Map>()
          .map((entry) => UserCarInterest.fromJson(
                Map<String, dynamic>.from(entry),
              ))
          .where((interest) => interest.brandId.isNotEmpty)
          .take(maxInterests)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> recordInterest({
    required String brandId,
    String? modelKey,
  }) async {
    if (brandId.isEmpty) return;

    final normalizedModel =
        modelKey != null && modelKey.isNotEmpty ? modelKey : null;
    final entry = UserCarInterest(
      brandId: brandId,
      modelKey: normalizedModel,
    );

    final current = await getInterests();
    final deduped =
        current.where((interest) => !interest.matches(entry)).toList();
    final updated = [entry, ...deduped].take(maxInterests).toList();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(updated.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> recordFromCar(Map<String, dynamic> car) async {
    final brandId = car['brandId']?.toString();
    if (brandId == null || brandId.isEmpty) return;

    await recordInterest(
      brandId: brandId,
      modelKey: car['modelKey']?.toString(),
    );
  }
}
