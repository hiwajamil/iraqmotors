import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
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

  RecaptchaVerifier? _recaptchaVerifier;

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

  /// Starts Firebase phone verification and completes when [codeSent],
  /// [verificationCompleted], or [verificationFailed] fires.
  /// Aggressive sanitize → validate → E.164 (`+9647501149414`) for Firebase.
  String _e164ForFirebase(String phoneNumber) {
    final cleaned = cleanPhoneInput(phoneNumber);
    _validatePhone(cleaned);
    return formatIraqPhoneE164(cleaned);
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

  /// Invisible reCAPTCHA modal on web (no DOM container — Firebase default).
  Future<PhoneVerificationResult> _verifyPhoneOnWeb(String e164) async {
    _disposeRecaptchaVerifier();
    FirebaseAuthException? recaptchaError;

    try {
      _recaptchaVerifier = RecaptchaVerifier(
        auth: FirebaseAuthPlatform.instanceFor(
          app: _auth.app,
          pluginConstants: _auth.pluginConstants,
        ),
        onSuccess: () => debugPrint('[Auth] reCAPTCHA solved'),
        onError: (FirebaseAuthException e) {
          debugPrint(
            '[Auth] reCAPTCHA onError: code=${e.code} message=${e.message}',
          );
          recaptchaError = e;
        },
        onExpired: () {
          debugPrint('[Auth] reCAPTCHA expired');
          recaptchaError = FirebaseAuthException(
            code: 'recaptcha-expired',
            message: 'reCAPTCHA expired. Please tap Send Code again.',
          );
        },
      );
      debugPrint('[Auth] Rendering invisible reCAPTCHA verifier…');
      await _recaptchaVerifier!.render();

      if (recaptchaError != null) {
        throw recaptchaError!;
      }

      final verifier = _recaptchaVerifier;
      if (verifier == null) {
        throw FirebaseAuthException(
          code: 'recaptcha-not-initialized',
          message:
              'reCAPTCHA verifier was not initialized. Reload the page and try again.',
        );
      }
      debugPrint('[Auth] signInWithPhoneNumber e164="$e164" with reCAPTCHA');

      final confirmation = await _auth.signInWithPhoneNumber(
        e164,
        verifier,
      );
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
    } finally {
      // Keep verifier alive until OTP is confirmed; cleared on next send.
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

  void _disposeRecaptchaVerifier() {
    _recaptchaVerifier?.clear();
    _recaptchaVerifier = null;
  }

  Future<void> registerIndividual({
    required String fullName,
    required String phone,
    required String password,
    required String verificationId,
    required String smsCode,
    PhoneAuthCredential? autoVerifiedCredential,
  }) async {
    _validatePhone(phone);
    final normalizedPhone = normalizeIraqPhone(phone);

    final user = await _signInWithPhoneOtp(
      verificationId: verificationId,
      smsCode: smsCode,
      autoVerifiedCredential: autoVerifiedCredential,
    );

    try {
      await _linkEmailPasswordIfNeeded(user, phone, password);
      await user.updateDisplayName(fullName.trim());

      final profile = UserProfile(
        uid: user.uid,
        accountType: AccountType.individual,
        phone: normalizedPhone,
        displayName: fullName.trim(),
      );
      await _saveProfile(profile);
    } catch (e) {
      await _auth.signOut();
      rethrow;
    }
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
    _validatePhone(phone);
    final normalizedPhone = normalizeIraqPhone(phone);

    final user = await _signInWithPhoneOtp(
      verificationId: verificationId,
      smsCode: smsCode,
      autoVerifiedCredential: autoVerifiedCredential,
    );

    try {
      await _linkEmailPasswordIfNeeded(user, phone, password);

      final displayName = showroomName.trim();
      await user.updateDisplayName(displayName);

      final profile = UserProfile(
        uid: user.uid,
        accountType: AccountType.showroom,
        phone: normalizedPhone,
        displayName: displayName,
        showroomName: showroomName.trim(),
        ownerName: ownerName.trim(),
        city: city,
      );
      await _saveProfile(profile);
    } catch (e) {
      await _auth.signOut();
      rethrow;
    }
  }

  Future<void> signIn({
    required String phone,
    required String password,
  }) async {
    _validatePhone(phone);
    final email = phoneToAuthEmail(phone);
    await _auth.signInWithEmailAndPassword(email: email, password: password);
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
