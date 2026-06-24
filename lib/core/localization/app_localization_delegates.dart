import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:iq_motors/l10n/app_localizations.dart';

/// Framework localization fallbacks for locales not shipped in Flutter SDK (e.g. Kurdish).
abstract final class KuLocaleFallbackDelegates {
  static const List<LocalizationsDelegate<dynamic>> delegates = [
    _KuMaterialLocalizationsDelegate(),
    _KuCupertinoLocalizationsDelegate(),
    _KuWidgetsLocalizationsDelegate(),
  ];
}

class _KuMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _KuMaterialLocalizationsDelegate();

  static const _fallback = Locale('ar');

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ku';

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    return GlobalMaterialLocalizations.delegate.load(_fallback);
  }

  @override
  bool shouldReload(_KuMaterialLocalizationsDelegate old) => false;
}

class _KuCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const _KuCupertinoLocalizationsDelegate();

  static const _fallback = Locale('ar');

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ku';

  @override
  Future<CupertinoLocalizations> load(Locale locale) {
    return GlobalCupertinoLocalizations.delegate.load(_fallback);
  }

  @override
  bool shouldReload(_KuCupertinoLocalizationsDelegate old) => false;
}

class _KuWidgetsLocalizationsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const _KuWidgetsLocalizationsDelegate();

  static const _fallback = Locale('ar');

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ku';

  @override
  Future<WidgetsLocalizations> load(Locale locale) {
    return GlobalWidgetsLocalizations.delegate.load(_fallback);
  }

  @override
  bool shouldReload(_KuWidgetsLocalizationsDelegate old) => false;
}

/// Full delegate list for [MaterialApp] — app strings first, Kurdish fallbacks, then globals.
const List<LocalizationsDelegate<dynamic>> appLocalizationDelegates = [
  AppLocalizations.delegate,
  ...KuLocaleFallbackDelegates.delegates,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];
