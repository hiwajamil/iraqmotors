import 'package:iq_motors/core/platform/pwa_install_stub.dart'
    if (dart.library.html) 'package:iq_motors/core/platform/pwa_install_web.dart'
    as impl;

/// Whether the app is already running as an installed PWA.
bool pwaIsStandalone() => impl.pwaIsStandalone();

/// Whether the browser has offered an install prompt.
bool pwaCanInstall() => impl.pwaCanInstall();

/// Shows the native install dialog when available.
///
/// Returns `accepted`, `dismissed`, or `unavailable`.
Future<String> pwaPromptInstall() => impl.pwaPromptInstall();

/// Subscribes to installability / installed events. Returns an unsubscribe.
void Function() pwaListenInstallability(void Function() onChanged) =>
    impl.pwaListenInstallability(onChanged);
