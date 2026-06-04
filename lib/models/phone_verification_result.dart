import 'package:firebase_auth/firebase_auth.dart';

/// Result of [AuthService.verifyPhoneNumber] once Firebase invokes a callback.
class PhoneVerificationResult {
  const PhoneVerificationResult({
    this.verificationId,
    this.resendToken,
    this.autoVerifiedCredential,
  });

  final String? verificationId;
  final int? resendToken;
  final PhoneAuthCredential? autoVerifiedCredential;

  bool get isAutoVerified => autoVerifiedCredential != null;
}
