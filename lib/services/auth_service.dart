import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:flutter/foundation.dart';

import '../core/phone_auth_email.dart';
import '../core/recaptcha_enterprise_config.dart';
import '../core/super_admin_config.dart';
import '../models/account_type.dart';
import '../models/phone_verification_result.dart';
import '../models/user_profile.dart';

enum AuthErrorCode {
  invalidPhone,
  phoneAlreadyRegistered,
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

  /// Web-only reCAPTCHA Enterprise verifier bound to `#recaptcha-container`.
  RecaptchaVerifier? _webRecaptchaVerifier;

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
  /// fire from Firebase callbacks; on web, reCAPTCHA Enterprise + phone verification.
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

        await _verifyPhoneNumberOnWeb(
          e164: e164,
          verificationCompleted: (credential) {
            debugPrint('[Auth] sendOtp verificationCompleted (auto-verify)');
            onAutoVerified?.call(credential);
          },
          verificationFailed: onError,
          codeSent: (verificationId, _) {
            debugPrint('[Auth] sendOtp codeSent: verificationId=$verificationId');
            onCodeSent(verificationId);
          },
          codeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
        );
        return;
      }

      await _ensureRecaptchaEnterpriseReady();
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
      print('Phone Auth Exception: $e');
      onError(e);
    } on AuthException catch (e) {
      final code = switch (e.code) {
        AuthErrorCode.invalidPhone => 'invalid-phone-number',
        AuthErrorCode.phoneAlreadyRegistered => 'email-already-in-use',
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
      print('Phone Auth Exception: $e');
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
      if (kIsWeb) {
        _disposeWebRecaptchaVerifier();
      }
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
      print('Phone Auth Exception: $e');
      debugPrint('[Auth] verifyPhoneNumber unexpected error: $e\n$stack');
      throw FirebaseAuthException(
        code: 'internal-error',
        message: e.toString(),
      );
    }
  }

  Future<void> _ensureRecaptchaEnterpriseReady() async {
    await _auth.setLanguageCode('ar');
    await _auth.initializeRecaptchaConfig();
    if (kDebugMode) {
      debugPrint(
        '[Auth] reCAPTCHA Enterprise ready '
        '(web key ${RecaptchaEnterpriseConfig.webSiteKey.substring(0, 8)}…, '
        'android ${RecaptchaEnterpriseConfig.androidSiteKey.substring(0, 8)}…, '
        'ios ${RecaptchaEnterpriseConfig.iosSiteKey.substring(0, 8)}…)',
      );
    }
  }

  void _disposeWebRecaptchaVerifier() {
    try {
      _webRecaptchaVerifier?.clear();
    } catch (e) {
      debugPrint('[Auth] dispose web RecaptchaVerifier: $e');
    }
    _webRecaptchaVerifier = null;
  }

  RecaptchaVerifier _createWebRecaptchaVerifier({
    void Function(FirebaseAuthException error)? onVerifierError,
  }) {
    return RecaptchaVerifier(
      auth: FirebaseAuthPlatform.instanceFor(
        app: _auth.app,
        pluginConstants: _auth.pluginConstants,
      ),
      container: 'recaptcha-container',
      size: RecaptchaVerifierSize.compact,
      onSuccess: () => debugPrint('[Auth] reCAPTCHA Enterprise solved'),
      onError: (FirebaseAuthException e) {
        print('Phone Auth Exception: $e');
        debugPrint(
          '[Auth] reCAPTCHA Enterprise error: code=${e.code} message=${e.message}',
        );
        onVerifierError?.call(e);
      },
      onExpired: () => debugPrint('[Auth] reCAPTCHA Enterprise expired'),
    );
  }

  /// Web phone OTP via [RecaptchaVerifier] + [FirebaseAuth.verifyPhoneNumber].
  ///
  /// Flutter web wires [verifyPhoneNumber] to `PhoneAuthProvider.verifyPhoneNumber`
  /// with an internal verifier. We pass our own [RecaptchaVerifier] (required for
  /// reCAPTCHA Enterprise + `#recaptcha-container`) through [signInWithPhoneNumber],
  /// which calls the same underlying web API.
  Future<void> _verifyPhoneNumberOnWeb({
    required String e164,
    required PhoneVerificationCompleted verificationCompleted,
    required PhoneVerificationFailed verificationFailed,
    required void Function(String verificationId, int? resendToken) codeSent,
    void Function(String verificationId)? codeAutoRetrievalTimeout,
  }) async {
    await _ensureRecaptchaEnterpriseReady();
    _disposeWebRecaptchaVerifier();

    var settled = false;
    void settle(void Function() action) {
      if (settled) return;
      settled = true;
      action();
    }

    _webRecaptchaVerifier = _createWebRecaptchaVerifier(
      onVerifierError: (e) {
        settle(() {
          _disposeWebRecaptchaVerifier();
          verificationFailed(e);
        });
      },
    );

    debugPrint(
      '[Auth] verifyPhoneNumber (web) e164="$e164" host=${Uri.base.host} '
      'signInWithPhoneNumber + RecaptchaVerifier',
    );

    try {
      final confirmation = await _auth.signInWithPhoneNumber(
        e164,
        _webRecaptchaVerifier,
      );
      final verificationId = confirmation.verificationId;
      debugPrint(
        '[Auth] verifyPhoneNumber (web) codeSent: verificationId=$verificationId',
      );
      settle(() => codeSent(verificationId, null));
    } on FirebaseAuthException catch (e) {
      print('Phone Auth Exception: $e');
      debugPrint(
        '[Auth] Web phone verification failed: code=${e.code} message=${e.message?.toString()}',
      );
      settle(() {
        _disposeWebRecaptchaVerifier();
        verificationFailed(e);
      });
    } catch (e, stack) {
      print('Phone Auth Exception: $e');
      debugPrint('[Auth] Web phone verification failed: $e\n$stack');
      settle(() {
        _disposeWebRecaptchaVerifier();
        verificationFailed(
          FirebaseAuthException(
            code: 'internal-error',
            message: e.toString(),
          ),
        );
      });
    }
  }

  Future<PhoneVerificationResult> _verifyPhoneOnWeb(String e164) async {
    final completer = Completer<PhoneVerificationResult>();

    await _verifyPhoneNumberOnWeb(
      e164: e164,
      verificationCompleted: (credential) {
        if (!completer.isCompleted) {
          completer.complete(
            PhoneVerificationResult(autoVerifiedCredential: credential),
          );
        }
      },
      verificationFailed: (e) {
        if (!completer.isCompleted) {
          completer.completeError(e);
        }
      },
      codeSent: (verificationId, resendToken) {
        if (!completer.isCompleted) {
          completer.complete(
            PhoneVerificationResult(
              verificationId: verificationId,
              resendToken: resendToken,
            ),
          );
        }
      },
      codeAutoRetrievalTimeout: (verificationId) {
        debugPrint(
          '[Auth] codeAutoRetrievalTimeout: verificationId=$verificationId',
        );
      },
    );

    return completer.future;
  }

  Future<PhoneVerificationResult> _verifyPhoneOnMobile(
    String e164, {
    void Function(String verificationId)? onCodeAutoRetrievalTimeout,
  }) async {
    final completer = Completer<PhoneVerificationResult>();

    try {
      await _ensureRecaptchaEnterpriseReady();
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

  Future<void> signOut() async {
    _disposeWebRecaptchaVerifier();
    await _auth.signOut();
  }

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
