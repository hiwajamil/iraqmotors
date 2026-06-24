import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iq_motors/features/auth/domain/models/user_profile.dart';
import 'package:iq_motors/features/auth/data/services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;
  if (user == null) {
    return Stream.value(null);
  }
  return ref.watch(authServiceProvider).profileStream(user.uid);
});
