import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/locale_config.dart';

const _localeStorageKey = 'app_locale';

/// Boot-time locale loaded in [main] before [runApp].
Locale? _bootLocale;

/// Sets the initial locale before the provider is first read.
void setBootLocale(Locale locale) {
  _bootLocale = locale;
}

/// Loads persisted locale or returns Kurdish as default.
Future<Locale> loadSavedLocale() async {
  final prefs = await SharedPreferences.getInstance();
  final code = prefs.getString(_localeStorageKey);
  if (code == null) return AppLocaleConfig.defaultLocale;
  return AppLocaleConfig.resolve(Locale(code)) ?? AppLocaleConfig.defaultLocale;
}

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() => _bootLocale ?? AppLocaleConfig.defaultLocale;

  Future<void> setLocale(Locale locale) async {
    final resolved = AppLocaleConfig.resolve(locale) ?? AppLocaleConfig.defaultLocale;
    if (state == resolved) return;
    state = resolved;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeStorageKey, resolved.languageCode);
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);
