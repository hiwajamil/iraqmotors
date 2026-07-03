import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iq_motors/features/marketplace/data/services/user_interest_service.dart';
import 'package:iq_motors/features/storage/presentation/providers/storage_providers.dart';

final userInterestServiceProvider = Provider<UserInterestService>((ref) {
  return UserInterestService();
});

/// Bumped after each recorded interest so [recommendedCarsProvider] refetches.
class UserInterestRevisionNotifier extends Notifier<int> {
  @override
  int build() => 0;

  Future<void> record({
    required String brandId,
    String? modelKey,
  }) async {
    await ref.read(userInterestServiceProvider).recordInterest(
          brandId: brandId,
          modelKey: modelKey,
        );
    state++;
  }

  Future<void> recordFromCar(Map<String, dynamic> car) async {
    await ref.read(userInterestServiceProvider).recordFromCar(car);
    state++;
  }
}

final userInterestRevisionProvider =
    NotifierProvider<UserInterestRevisionNotifier, int>(
  UserInterestRevisionNotifier.new,
);

class RecommendedCarsResult {
  const RecommendedCarsResult({
    required this.cars,
    required this.isPersonalized,
  });

  final List<Map<String, dynamic>> cars;
  final bool isPersonalized;
}

/// One-shot fetch for the home recommended row (not a live Firestore stream).
final recommendedCarsProvider =
    FutureProvider<RecommendedCarsResult>((ref) async {
  ref.watch(userInterestRevisionProvider);

  final service = ref.read(userInterestServiceProvider);
  final interests = await service.getInterests();
  final db = ref.read(carDatabaseServiceProvider);

  if (interests.isEmpty) {
    final cars = await db.fetchTrendingCars(limit: 10);
    return RecommendedCarsResult(cars: cars, isPersonalized: false);
  }

  final cars = await db.fetchRecommendedCars(interests, limit: 10);
  return RecommendedCarsResult(cars: cars, isPersonalized: true);
});
