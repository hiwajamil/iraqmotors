import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/car_database_service.dart';
import 'auth_providers.dart';
import 'storage_providers.dart';

/// IDs of cars the signed-in user has favorited.
final favoritesProvider =
    NotifierProvider<FavoritesNotifier, Set<String>>(FavoritesNotifier.new);

class FavoritesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    ref.listen<AsyncValue<User?>>(authStateProvider, (_, next) {
      unawaited(_loadFavorites(next.value?.uid));
    });

    final userId = ref.read(authStateProvider).value?.uid;
    if (userId != null) {
      unawaited(_loadFavorites(userId));
    }

    return {};
  }

  Future<void> _loadFavorites(String? userId) async {
    if (userId == null) {
      state = {};
      return;
    }

    try {
      final docs = await ref
          .read(carDatabaseServiceProvider)
          .fetchFavoriteAds(userId);
      state = docs
          .map((doc) => doc['id']?.toString())
          .whereType<String>()
          .toSet();
    } on CarDatabaseException {
      state = {};
    }
  }

  bool isFavorited(String? carId) =>
      carId != null && carId.isNotEmpty && state.contains(carId);

  /// Toggles favorite state. Returns `true` when the car is now favorited.
  Future<bool> toggle(Map<String, dynamic> car) async {
    final userId = ref.read(authStateProvider).value?.uid;
    if (userId == null) {
      throw const FavoritesAuthRequired();
    }

    final adId = car['id']?.toString();
    if (adId == null || adId.isEmpty) {
      throw CarDatabaseException('Car listing not found.');
    }

    final db = ref.read(carDatabaseServiceProvider);
    if (state.contains(adId)) {
      await db.unfavoriteCarAd(adId: adId, userId: userId);
      state = Set<String>.from(state)..remove(adId);
      return false;
    }

    await db.favoriteCarAd(
      adId: adId,
      userId: userId,
      seedData: _seedDataForFavorite(car),
    );
    state = Set<String>.from(state)..add(adId);
    return true;
  }
}

Map<String, dynamic> _seedDataForFavorite(Map<String, dynamic> car) {
  final make = car['make']?.toString() ?? '';
  final model = car['model']?.toString() ?? '';
  final title = '$make $model'.trim();

  return {
    ...car,
    if (title.isNotEmpty) 'title': title,
  };
}

class FavoritesAuthRequired implements Exception {
  const FavoritesAuthRequired();
}
