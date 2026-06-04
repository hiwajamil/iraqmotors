import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/phone_auth_email.dart';
import '../models/phone_verification_result.dart';
import '../services/auth_service.dart';

/// Phone verification orchestration for the registration screen.
class AuthController {
  AuthController(this._authService);

  final AuthService _authService;

  bool isSendingCode = false;

  /// Cleans spaces, validates Iraq mobile, then starts Firebase verification.
  Future<PhoneVerificationResult?> sendVerificationCode({
    required String rawPhone,
    required void Function(bool isSending) onSendingChanged,
    required void Function(String verificationId) onCodeAutoRetrievalTimeout,
    void Function(PhoneVerificationResult result)? onSuccess,
    void Function(String message)? onError,
  }) async {
    if (isSendingCode) return null;

    final phone = cleanPhoneInput(rawPhone.trim());
    if (phone.isEmpty) {
      onError?.call('enter_phone_first');
      return null;
    }
    if (!isValidIraqMobile(phone)) {
      onError?.call('invalid_phone');
      return null;
    }

    final e164 = formatIraqPhoneE164(phone);
    debugPrint('[AuthController] sendVerificationCode local=$phone e164=$e164');

    isSendingCode = true;
    onSendingChanged(true);

    try {
      final result = await _authService.verifyPhoneNumber(
        phone,
        onCodeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
      );
      onSuccess?.call(result);
      return result;
    } on FirebaseAuthException catch (e) {
      debugPrint(
        '[AuthController] FirebaseAuthException: code=${e.code} message=${e.message}',
      );
      onError?.call(formatFirebaseAuthError(e));
      return null;
    } on AuthException catch (e) {
      onError?.call(e.code.name);
      return null;
    } catch (e, stack) {
      debugPrint('[AuthController] sendVerificationCode failed: $e\n$stack');
      onError?.call(e.toString());
      return null;
    } finally {
      isSendingCode = false;
      onSendingChanged(false);
    }
  }

  /// Exact Firebase message for debugging (reCAPTCHA, quota, formatting, etc.).
  static String formatFirebaseAuthError(FirebaseAuthException e) {
    final message = e.message?.trim();
    if (message != null && message.isNotEmpty) {
      return message;
    }
    return '${e.code}: No additional details from Firebase.';
  }
}
