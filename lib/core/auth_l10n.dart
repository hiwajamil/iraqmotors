import 'package:firebase_auth/firebase_auth.dart';

import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';

extension AuthMessagesL10n on AppLocalizations {
  String messageForAuthError(AuthErrorCode code) {
    return switch (code) {
      AuthErrorCode.invalidPhone => authInvalidPhone,
      AuthErrorCode.registrationFailed => authRegistrationFailed,
      AuthErrorCode.sendCodeFirst => authSendCodeFirst,
    };
  }

  String messageForFirebaseAuthException(FirebaseAuthException e) {
    return switch (e.code) {
      'email-already-in-use' ||
      'credential-already-in-use' ||
      'account-exists-with-different-credential' =>
        authEmailAlreadyInUse,
      'invalid-email' => authInvalidPhone,
      'weak-password' => authWeakPassword,
      'user-not-found' ||
      'invalid-credential' ||
      'wrong-password' =>
        authWrongCredentials,
      'too-many-requests' => authTooManyRequests,
      'network-request-failed' => authNetworkError,
      'invalid-verification-code' => otpInvalid,
      'invalid-verification-id' || 'session-expired' =>
        authVerificationExpired,
      'quota-exceeded' => authTooManyRequests,
      'captcha-check-failed' => authCaptchaFailed,
      'invalid-phone-number' => authInvalidPhone,
      _ => authGenericError,
    };
  }
}
