import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:iq_motors/core/platform/pwa_install.dart';

const _dismissStorageKey = 'pwa_install_banner_dismissed';

@immutable
class PwaInstallState {
  const PwaInstallState({
    required this.canInstall,
    required this.isStandalone,
    required this.dismissed,
  });

  final bool canInstall;
  final bool isStandalone;
  final bool dismissed;

  bool get shouldShowBanner =>
      kIsWeb && canInstall && !isStandalone && !dismissed;

  PwaInstallState copyWith({
    bool? canInstall,
    bool? isStandalone,
    bool? dismissed,
  }) {
    return PwaInstallState(
      canInstall: canInstall ?? this.canInstall,
      isStandalone: isStandalone ?? this.isStandalone,
      dismissed: dismissed ?? this.dismissed,
    );
  }
}

class PwaInstallNotifier extends Notifier<PwaInstallState> {
  void Function()? _unsubscribe;

  @override
  PwaInstallState build() {
    ref.onDispose(() {
      _unsubscribe?.call();
      _unsubscribe = null;
    });

    if (!kIsWeb) {
      return const PwaInstallState(
        canInstall: false,
        isStandalone: false,
        dismissed: true,
      );
    }

    _unsubscribe = pwaListenInstallability(_refresh);
    Future<void>.microtask(_bootstrap);
    return PwaInstallState(
      canInstall: pwaCanInstall(),
      isStandalone: pwaIsStandalone(),
      dismissed: false,
    );
  }

  Future<void> _bootstrap() async {
    var dismissed = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      dismissed = prefs.getBool(_dismissStorageKey) ?? false;
    } catch (_) {}
    if (!ref.mounted) return;
    state = state.copyWith(
      canInstall: pwaCanInstall(),
      isStandalone: pwaIsStandalone(),
      dismissed: dismissed,
    );
  }

  void _refresh() {
    if (!ref.mounted) return;
    state = state.copyWith(
      canInstall: pwaCanInstall(),
      isStandalone: pwaIsStandalone(),
    );
  }

  Future<String> promptInstall() async {
    final outcome = await pwaPromptInstall();
    _refresh();
    return outcome;
  }

  Future<void> dismissBanner() async {
    state = state.copyWith(dismissed: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_dismissStorageKey, true);
    } catch (_) {}
  }
}

final pwaInstallProvider =
    NotifierProvider<PwaInstallNotifier, PwaInstallState>(PwaInstallNotifier.new);
