import 'phone_auth_email.dart';

/// Designated platform super-admin account (Firebase Auth email).
const String kSuperAdminEmail = 'hiwa.constructions@gmail.com';

/// Super-admin phone in local Iraqi format (matches sign-in / registration fields).
const String kSuperAdminPhoneLocal = '07500000000';

bool isSuperAdminEmail(String? email) {
  if (email == null || email.trim().isEmpty) return false;
  return email.trim().toLowerCase() == kSuperAdminEmail.toLowerCase();
}

bool isSuperAdminPhone(String? phone) {
  if (phone == null || phone.trim().isEmpty) return false;
  return normalizeIraqPhone(phone) == normalizeIraqPhone(kSuperAdminPhoneLocal);
}

/// Firebase email for phone-based accounts (`964…@iqmotors.app`) or the real Gmail.
bool isSuperAdminAuthEmail(String? email) {
  if (email == null || email.trim().isEmpty) return false;
  final normalized = email.trim().toLowerCase();
  if (normalized == kSuperAdminEmail.toLowerCase()) return true;
  return normalized == phoneToAuthEmail(kSuperAdminPhoneLocal).toLowerCase();
}

bool isSuperAdminUser({String? email, String? phone}) {
  return isSuperAdminEmail(email) ||
      isSuperAdminPhone(phone) ||
      isSuperAdminAuthEmail(email);
}
