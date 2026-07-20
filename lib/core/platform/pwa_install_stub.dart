bool pwaIsStandalone() => false;

bool pwaCanInstall() => false;

Future<String> pwaPromptInstall() async => 'unavailable';

void Function() pwaListenInstallability(void Function() onChanged) => () {};
