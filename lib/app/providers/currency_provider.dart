import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:iq_motors/core/services/currency_service.dart';

const _currencyStorageKey = 'app_currency_mode';

CurrencyMode? _bootCurrencyMode;

void setBootCurrencyMode(CurrencyMode mode) {
  _bootCurrencyMode = mode;
}

Future<CurrencyMode> loadSavedCurrencyMode() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_currencyStorageKey);
    if (name == null) return CurrencyMode.usd;
    return CurrencyMode.values.firstWhere(
      (e) => e.name == name,
      orElse: () => CurrencyMode.usd,
    );
  } catch (_) {
    return CurrencyMode.usd;
  }
}

class CurrencyModeNotifier extends Notifier<CurrencyMode> {
  @override
  CurrencyMode build() => _bootCurrencyMode ?? CurrencyMode.usd;

  Future<void> setCurrencyMode(CurrencyMode mode) async {
    if (state == mode) return;
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currencyStorageKey, mode.name);
    } catch (_) {}
  }

  void toggleCurrency() {
    final nextMode = state == CurrencyMode.usd ? CurrencyMode.iqd : CurrencyMode.usd;
    setCurrencyMode(nextMode);
  }
}

final currencyModeProvider =
    NotifierProvider<CurrencyModeNotifier, CurrencyMode>(
  CurrencyModeNotifier.new,
);

final currencyServiceProvider = Provider<CurrencyService>((ref) {
  return const CurrencyService();
});
