/// Strips whitespace before digit normalization (e.g. `0770 123 4567`).
String cleanPhoneInput(String input) => input.replaceAll(RegExp(r'\s+'), '');

/// Maps Iraqi/Kurdish mobile numbers to Firebase Auth email identifiers.
///
/// Firebase Email/Password is used so the UI can keep phone + password fields.
String normalizeIraqPhone(String input) {
  var digits = cleanPhoneInput(input).replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('964')) return digits;
  if (digits.startsWith('0') && digits.length >= 10) {
    return '964${digits.substring(1)}';
  }
  if (digits.length == 10 && digits.startsWith('7')) {
    return '964$digits';
  }
  return digits;
}

String phoneToAuthEmail(String phone) {
  return '${normalizeIraqPhone(phone)}@iqmotors.app';
}

bool isValidIraqMobile(String phone) {
  final normalized = normalizeIraqPhone(phone);
  return RegExp(r'^9647\d{9}$').hasMatch(normalized);
}

/// E.164 for Firebase Phone Auth: remove spaces, strip non-digits, drop leading `0`,
/// prefix `+964`. Example: `0770 123 4567` → `+9647701234567`.
String formatIraqPhoneE164(String input) {
  var digits = cleanPhoneInput(input).replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('964')) {
    digits = digits.substring(3);
  }
  if (digits.startsWith('0')) {
    digits = digits.substring(1);
  }
  return '+964$digits';
}

/// E.164 format required by Firebase Phone Auth (e.g. +9647501234567).
String phoneToE164(String phone) => formatIraqPhoneE164(phone);
