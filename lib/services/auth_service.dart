import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/phone_auth_email.dart';
import '../core/super_admin_config.dart';
import '../models/account_type.dart';
import '../models/phone_verification_result.dart';
import '../models/user_profile.dart';

enum AuthErrorCode {
  invalidPhone,
  registrationFailed,
  sendCodeFirst,
  userNotFound,
}

class AuthException implements Exception {
  AuthException(this.code);

  final AuthErrorCode code;

  @override
  String toString() => code.name;
}

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Stream<UserProfile?> profileStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserProfile.fromFirestore(doc);
    });
  }

  Future<UserProfile?> fetchProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromFirestore(doc);
  }

  /// Looks up a registered user by normalized Iraqi mobile number.
  Future<UserProfile?> findUserByPhone(String phone) async {
    _validatePhone(phone);
    final normalizedPhone = normalizeIraqPhone(phone);
    final snapshot = await _firestore
        .collection('users')
        .where('phone', isEqualTo: normalizedPhone)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return UserProfile.fromFirestore(snapshot.docs.first);
  }

  /// Starts Firebase phone verification and completes when [codeSent],
  /// [verificationCompleted], or [verificationFailed] fires.
  /// Aggressive sanitize → validate → E.164 (`+9647501149414`) for Firebase.
  String _e164ForFirebase(String phoneNumber) {
    final cleaned = cleanPhoneInput(phoneNumber);
    _validatePhone(cleaned);
    return formatIraqPhoneE164(cleaned);
  }

  /// Sends an OTP via Firebase Phone Auth. On mobile, [onCodeSent] / [onError]
  /// fire from Firebase callbacks; on web, reCAPTCHA + [signInWithPhoneNumber] runs first.
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(FirebaseAuthException error) onError,
    void Function(PhoneAuthCredential credential)? onAutoVerified,
    void Function(String verificationId)? onCodeAutoRetrievalTimeout,
  }) async {
    final e164 = _e164ForFirebase(phoneNumber);
    debugPrint('[Auth] sendOtp: e164="$e164" web=$kIsWeb');

    try {
      if (kIsWeb) {
        final host = Uri.base.host;
        if (host == 'localhost' ||
            host == '127.0.0.1' ||
            host == '0.0.0.0') {
          onError(
            FirebaseAuthException(
              code: 'invalid-app-credential',
              message:
                  'Phone verification does not work on localhost. '
                  'Use https://iqmotors-d588d.web.app or run with '
                  '--web-hostname=127.0.0.1',
            ),
          );
          return;
        }

        final result = await _verifyPhoneOnWeb(e164);
        final verificationId = result.verificationId;
        if (verificationId == null || verificationId.isEmpty) {
          onError(
            FirebaseAuthException(
              code: 'missing-verification-id',
              message: 'Phone verification did not return a verification ID.',
            ),
          );
          return;
        }
        onCodeSent(verificationId);
        return;
      }

      await _auth.verifyPhoneNumber(
        phoneNumber: e164,
        timeout: const Duration(seconds: 120),
        verificationCompleted: (PhoneAuthCredential credential) {
          debugPrint('[Auth] sendOtp verificationCompleted (auto-verify)');
          onAutoVerified?.call(credential);
        },
        verificationFailed: onError,
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('[Auth] sendOtp codeSent: verificationId=$verificationId');
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint(
            '[Auth] sendOtp codeAutoRetrievalTimeout: verificationId=$verificationId',
          );
          onCodeAutoRetrievalTimeout?.call(verificationId);
        },
      );
    } on FirebaseAuthException catch (e) {
      onError(e);
    } on AuthException catch (e) {
      final code = switch (e.code) {
        AuthErrorCode.invalidPhone => 'invalid-phone-number',
        AuthErrorCode.sendCodeFirst => 'invalid-verification-id',
        AuthErrorCode.registrationFailed => 'internal-error',
        AuthErrorCode.userNotFound => 'user-not-found',
      };
      onError(
        FirebaseAuthException(
          code: code,
          message: e.toString(),
        ),
      );
    } catch (e, stack) {
      debugPrint('[Auth] sendOtp unexpected error: $e\n$stack');
      onError(
        FirebaseAuthException(
          code: 'internal-error',
          message: e.toString(),
        ),
      );
    }
  }

  /// Verifies the SMS code, signs the user in, links email/password when provided,
  /// and persists [userData] to the `users` collection.
  Future<void> verifyOtpAndRegister({
    required String verificationId,
    required String smsCode,
    required Map<String, dynamic> userData,
    PhoneAuthCredential? autoVerifiedCredential,
  }) async {
    final phone = userData['phoneNumber'] as String? ?? '';
    _validatePhone(phone);
    final normalizedPhone = normalizeIraqPhone(phone);
    final password = userData['password'] as String?;

    final user = await _signInWithPhoneOtp(
      verificationId: verificationId,
      smsCode: smsCode,
      autoVerifiedCredential: autoVerifiedCredential,
    );

    try {
      if (password != null && password.isNotEmpty) {
        await _linkEmailPasswordIfNeeded(user, phone, password);
      }

      final accountType = _accountTypeFromUserData(userData);
      final fullName = (userData['fullName'] as String? ?? '').trim();
      if (fullName.isNotEmpty) {
        await user.updateDisplayName(fullName);
      }

      final profile = UserProfile(
        uid: user.uid,
        accountType: accountType,
        phone: normalizedPhone,
        displayName: accountType == AccountType.showroom
            ? (userData['showroomName'] as String? ?? fullName).trim()
            : fullName,
        showroomName: (userData['showroomName'] as String?)?.trim(),
        ownerName: (userData['ownerName'] as String?)?.trim(),
        city: userData['city'] as String?,
        createdAt: DateTime.now(),
      );
      await _saveProfile(profile);
    } catch (e) {
      await _auth.signOut();
      rethrow;
    }
  }

  AccountType _accountTypeFromUserData(Map<String, dynamic> userData) {
    final raw = (userData['userType'] as String? ?? 'Normal').trim();
    return switch (raw.toLowerCase()) {
      'showroom' => AccountType.showroom,
      'normal' || 'individual' => AccountType.individual,
      _ => AccountType.individual,
    };
  }

  Future<PhoneVerificationResult> verifyPhoneNumber(
    String phoneNumber, {
    void Function(String verificationId)? onCodeAutoRetrievalTimeout,
  }) async {
    final cleaned = cleanPhoneInput(phoneNumber);
    final e164 = _e164ForFirebase(phoneNumber);
    debugPrint(
      '[Auth] verifyPhoneNumber: raw="$phoneNumber" cleaned="$cleaned" e164="$e164" web=$kIsWeb',
    );

    try {
      if (kIsWeb) {
        return await _verifyPhoneOnWeb(e164);
      }
      return await _verifyPhoneOnMobile(
        e164,
        onCodeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
      );
    } on FirebaseAuthException {
      rethrow;
    } catch (e, stack) {
      debugPrint('[Auth] verifyPhoneNumber unexpected error: $e\n$stack');
      throw FirebaseAuthException(
        code: 'internal-error',
        message: e.toString(),
      );
    }
  }

  /// Web phone OTP — Firebase manages reCAPTCHA inside [signInWithPhoneNumber].
  ///
  /// Do not call [RecaptchaVerifier.render] beforehand; pre-rendering can expire
  /// the token before SMS is sent and triggers `captcha-check-failed`.
  Future<PhoneVerificationResult> _verifyPhoneOnWeb(String e164) async {
    try {
      await _auth.setLanguageCode('ar');
      debugPrint(
        '[Auth] signInWithPhoneNumber e164="$e164" host=${Uri.base.host}',
      );

      final confirmation = await _auth.signInWithPhoneNumber(e164);
      debugPrint(
        '[Auth] signInWithPhoneNumber succeeded: verificationId=${confirmation.verificationId}',
      );
      return PhoneVerificationResult(
        verificationId: confirmation.verificationId,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint(
        '[Auth] Web phone verification failed: code=${e.code} message=${e.message?.toString()}',
      );
      rethrow;
    }
  }

  Future<PhoneVerificationResult> _verifyPhoneOnMobile(
    String e164, {
    void Function(String verificationId)? onCodeAutoRetrievalTimeout,
  }) async {
    final completer = Completer<PhoneVerificationResult>();

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: e164,
        timeout: const Duration(seconds: 120),
        verificationCompleted: (PhoneAuthCredential credential) {
          debugPrint('[Auth] verificationCompleted (auto-verify)');
          if (!completer.isCompleted) {
            completer.complete(
              PhoneVerificationResult(autoVerifiedCredential: credential),
            );
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint(
            '[Auth] verificationFailed: code=${e.code} message=${e.message}',
          );
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint(
            '[Auth] codeSent: verificationId=$verificationId resendToken=$resendToken',
          );
          if (!completer.isCompleted) {
            completer.complete(
              PhoneVerificationResult(
                verificationId: verificationId,
                resendToken: resendToken,
              ),
            );
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint(
            '[Auth] codeAutoRetrievalTimeout: verificationId=$verificationId',
          );
          onCodeAutoRetrievalTimeout?.call(verificationId);
        },
      );
    } catch (e, stack) {
      debugPrint('[Auth] verifyPhoneNumber platform error: $e\n$stack');
      if (!completer.isCompleted) {
        if (e is FirebaseAuthException) {
          completer.completeError(e);
        } else {
          completer.completeError(
            FirebaseAuthException(
              code: 'internal-error',
              message: e.toString(),
            ),
          );
        }
      }
    }

    return completer.future.timeout(
      const Duration(seconds: 125),
      onTimeout: () => throw FirebaseAuthException(
        code: 'timeout',
        message:
            'Phone verification timed out. Check your number and try again.',
      ),
    );
  }

  Future<void> registerIndividual({
    required String fullName,
    required String phone,
    required String password,
    required String verificationId,
    required String smsCode,
    PhoneAuthCredential? autoVerifiedCredential,
  }) async {
    await verifyOtpAndRegister(
      verificationId: verificationId,
      smsCode: smsCode,
      autoVerifiedCredential: autoVerifiedCredential,
      userData: {
        'fullName': fullName,
        'phoneNumber': phone,
        'userType': 'Normal',
        'password': password,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );
  }

  Future<void> registerShowroom({
    required String showroomName,
    required String ownerName,
    required String phone,
    required String password,
    required String city,
    required String verificationId,
    required String smsCode,
    PhoneAuthCredential? autoVerifiedCredential,
  }) async {
    await verifyOtpAndRegister(
      verificationId: verificationId,
      smsCode: smsCode,
      autoVerifiedCredential: autoVerifiedCredential,
      userData: {
        'fullName': ownerName,
        'phoneNumber': phone,
        'userType': 'Showroom',
        'password': password,
        'showroomName': showroomName,
        'ownerName': ownerName,
        'city': city,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );
  }

  Future<void> signIn({
    required String phone,
    required String password,
  }) async {
    _validatePhone(phone);
    final email = phoneToAuthEmail(phone);
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw AuthException(AuthErrorCode.userNotFound);
      }
      rethrow;
    }
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Super-admin may use real Gmail or the phone-linked `@iqmotors.app` email.
  Future<void> signInAsSuperAdmin({
    required String email,
    required String phone,
    required String password,
  }) async {
    FirebaseAuthException? emailFailure;

    if (isSuperAdminEmail(email)) {
      try {
        await signInWithEmail(email: email, password: password);
        return;
      } on FirebaseAuthException catch (e) {
        if (!_isCredentialError(e)) rethrow;
        emailFailure = e;
      }
    }

    final cleanedPhone = cleanPhoneInput(phone);
    if (cleanedPhone.isNotEmpty) {
      if (!isSuperAdminPhone(phone)) {
        if (emailFailure != null) throw emailFailure;
        throw AuthException(AuthErrorCode.invalidPhone);
      }
      await signIn(phone: phone, password: password);
      return;
    }

    if (emailFailure != null) throw emailFailure;
    await signInWithEmail(email: email, password: password);
  }

  bool _isCredentialError(FirebaseAuthException e) {
    return switch (e.code) {
      'invalid-credential' || 'wrong-password' || 'user-not-found' => true,
      _ => false,
    };
  }

  Future<void> signOut() => _auth.signOut();

  Future<User> _signInWithPhoneOtp({
    required String verificationId,
    required String smsCode,
    PhoneAuthCredential? autoVerifiedCredential,
  }) async {
    final PhoneAuthCredential phoneCredential;
    if (autoVerifiedCredential != null) {
      phoneCredential = autoVerifiedCredential;
    } else {
      if (verificationId.isEmpty) {
        throw AuthException(AuthErrorCode.sendCodeFirst);
      }
      phoneCredential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );
    }

    final userCredential = await _auth.signInWithCredential(phoneCredential);
    final user = userCredential.user;
    if (user == null) {
      throw AuthException(AuthErrorCode.registrationFailed);
    }
    return user;
  }

  Future<void> _linkEmailPasswordIfNeeded(
    User user,
    String phone,
    String password,
  ) async {
    final hasPasswordProvider = user.providerData.any(
      (info) => info.providerId == 'password',
    );
    if (hasPasswordProvider) return;

    final email = phoneToAuthEmail(phone);
    await user.linkWithCredential(
      EmailAuthProvider.credential(email: email, password: password),
    );
  }

  Future<void> _saveProfile(UserProfile profile) async {
    await _firestore
        .collection('users')
        .doc(profile.uid)
        .set(profile.toFirestore());
  }

  void _validatePhone(String phone) {
    if (!isValidIraqMobile(phone)) {
      throw AuthException(AuthErrorCode.invalidPhone);
    }
  }
}
