import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import 'firebase_web_config.dart';

extension AuthMessagesL10n on AppLocalizations {
  String messageForAuthError(AuthErrorCode code) {
    return switch (code) {
      AuthErrorCode.invalidPhone => authInvalidPhone,
      AuthErrorCode.registrationFailed => authRegistrationFailed,
      AuthErrorCode.sendCodeFirst => authSendCodeFirst,
      AuthErrorCode.userNotFound => authAccountNotFoundPrompt,
    };
  }

  String messageForFirebaseAuthException(FirebaseAuthException e) {
    final code = e.code.replaceFirst('auth/', '');
    final message = e.message?.trim();

    final mapped = switch (code) {
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
      'captcha-check-failed' ||
      'missing-recaptcha-token' ||
      'recaptcha-not-enabled' ||
      'recaptcha-expired' =>
        _messageForCaptchaFailure(),
      'invalid-phone-number' => authInvalidPhone,
      'invalid-app-credential' ||
      'missing-app-credential' ||
      'unauthorized-domain' ||
      'app-not-authorized' =>
        authInvalidAppCredential,
      'billing-not-enabled' => authBillingRequired,
      'operation-not-allowed' => authPhoneAuthDisabled,
      _ => null,
    };

    if (mapped != null) return mapped;

    if (message != null && message.isNotEmpty) {
      final lower = message.toLowerCase();
      if (lower.contains('blocked all requests') ||
          lower.contains('unusual activity') ||
          lower.contains('too many requests')) {
        return authDeviceBlocked;
      }
      return message;
    }

    return authGenericError;
  }

  String _messageForCaptchaFailure() {
    if (!kIsWeb) return authCaptchaFailed;

    final host = Uri.base.host;
    if (host.isNotEmpty && !productionWebHosts.contains(host)) {
      // captcha-check-failed is often an unauthorized custom domain.
      return authInvalidAppCredential;
    }
    return authCaptchaFailed;
  }
}
