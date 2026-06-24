import 'package:iq_motors/l10n/app_localizations.dart';

/// Formats [dateTime] as a human-readable relative time string.
String formatRelativeTime(DateTime dateTime, AppLocalizations l10n) {
  final diff = DateTime.now().difference(dateTime);

  if (diff.inSeconds < 45) {
    return l10n.adminActivityJustNow;
  }
  if (diff.inMinutes < 60) {
    return l10n.adminActivityMinutesAgo(diff.inMinutes);
  }
  if (diff.inHours < 24) {
    return l10n.adminActivityHoursAgo(diff.inHours);
  }
  if (diff.inDays < 7) {
    return l10n.adminActivityDaysAgo(diff.inDays);
  }

  final day = dateTime.day.toString().padLeft(2, '0');
  final month = dateTime.month.toString().padLeft(2, '0');
  return '$day/$month/${dateTime.year}';
}
