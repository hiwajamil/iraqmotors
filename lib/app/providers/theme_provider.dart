import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themeStorageKey = 'app_theme_mode';

/// Boot-time theme mode loaded in [main] before [runApp].
ThemeMode? _bootThemeMode;

/// Sets the initial theme mode before the provider is first read.
void setBootThemeMode(ThemeMode mode) {
  _bootThemeMode = mode;
}

/// Loads persisted theme mode or defaults to [ThemeMode.system].
Future<ThemeMode> loadSavedThemeMode() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_themeStorageKey);
    if (name == null) return ThemeMode.system;
    return ThemeMode.values.firstWhere(
      (e) => e.name == name,
      orElse: () => ThemeMode.system,
    );
  } catch (_) {
    return ThemeMode.system;
  }
}

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => _bootThemeMode ?? ThemeMode.system;

  Future<void> setThemeMode(ThemeMode mode) async {
    if (state == mode) return;
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeStorageKey, mode.name);
    } catch (_) {}
  }

  /// Cycles system → light → dark → system so all three modes stay reachable.
  void toggleTheme() {
    final nextMode = switch (state) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    setThemeMode(nextMode);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
