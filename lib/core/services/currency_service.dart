import 'package:intl/intl.dart';

enum CurrencyMode {
  usd,
  iqd,
}

class CurrencyService {
  const CurrencyService({
    this.exchangeRateUsdToIqd = 1500,
  });

  /// Approximate exchange rate (1 USD = 1,500 IQD).
  final double exchangeRateUsdToIqd;

  /// Formats [amountUsd] into a localized primary currency string.
  String formatPrimary(int amountUsd, CurrencyMode mode) {
    if (mode == CurrencyMode.iqd) {
      final iqdAmount = (amountUsd * exchangeRateUsdToIqd).round();
      final formatted = NumberFormat('#,###', 'en_US').format(iqdAmount);
      return '$formatted د.ع';
    }
    final formatted = NumberFormat('#,###', 'en_US').format(amountUsd);
    return '\$$formatted';
  }

  /// Formats [amountUsd] into a secondary currency string for dual-currency badges.
  String formatSecondary(int amountUsd, CurrencyMode mode) {
    if (mode == CurrencyMode.iqd) {
      final formatted = NumberFormat('#,###', 'en_US').format(amountUsd);
      return '\$$formatted USD';
    }
    final iqdAmount = (amountUsd * exchangeRateUsdToIqd).round();
    final formatted = NumberFormat('#,###', 'en_US').format(iqdAmount);
    return '$formatted IQD';
  }

  /// Formats a complete dual-currency string (e.g. "$18,500 (27,750,000 IQD)").
  String formatDual(int amountUsd, CurrencyMode mode) {
    final primary = formatPrimary(amountUsd, mode);
    final secondary = formatSecondary(amountUsd, mode);
    return '$primary ($secondary)';
  }
}
