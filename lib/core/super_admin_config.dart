/// Designated platform super-admin account (Firebase Auth email).
const String kSuperAdminEmail = 'hiwa.constructions@gmail.com';

bool isSuperAdminEmail(String? email) {
  if (email == null || email.trim().isEmpty) return false;
  return email.trim().toLowerCase() == kSuperAdminEmail.toLowerCase();
}
