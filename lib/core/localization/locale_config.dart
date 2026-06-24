import 'package:flutter/material.dart';

/// Supported app locales — Kurdish is the default.
class AppLocaleConfig {
  AppLocaleConfig._();

  static const Locale defaultLocale = Locale('ku');

  static const List<Locale> supportedLocales = [
    Locale('ku'),
    Locale('ar'),
    Locale('en'),
  ];

  static bool isRtl(Locale locale) {
    return locale.languageCode == 'ku' || locale.languageCode == 'ar';
  }

  static TextDirection textDirectionFor(Locale locale) {
    return isRtl(locale) ? TextDirection.rtl : TextDirection.ltr;
  }

  static Locale? resolve(Locale? locale) {
    if (locale == null) return defaultLocale;
    for (final supported in supportedLocales) {
      if (supported.languageCode == locale.languageCode) {
        return supported;
      }
    }
    return defaultLocale;
  }
}
