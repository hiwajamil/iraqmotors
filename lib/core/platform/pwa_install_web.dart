// Web-only implementation; imported via conditional import on web.
// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:js_interop';

import 'package:web/web.dart';

@JS('iqMotorsPwaCanInstall')
external bool? get _iqMotorsPwaCanInstall;

@JS('iqMotorsPwaIsStandalone')
external JSFunction? get _iqMotorsPwaIsStandalone;

@JS('iqMotorsPwaPromptInstall')
external JSFunction? get _iqMotorsPwaPromptInstall;

bool pwaIsStandalone() {
  final fn = _iqMotorsPwaIsStandalone;
  if (fn == null) return false;
  final result = fn.callAsFunction();
  if (result == null) return false;
  return (result as JSBoolean).toDart;
}

bool pwaCanInstall() => _iqMotorsPwaCanInstall ?? false;

Future<String> pwaPromptInstall() async {
  final fn = _iqMotorsPwaPromptInstall;
  if (fn == null) return 'unavailable';
  try {
    final raw = await (fn.callAsFunction() as JSPromise<JSString>).toDart;
    return raw.toDart;
  } catch (_) {
    return 'unavailable';
  }
}

void Function() pwaListenInstallability(void Function() onChanged) {
  final EventListener listener = (Event _) {
    onChanged();
  }.toJS;

  window.addEventListener('iqmotors-pwa-installable', listener);
  window.addEventListener('iqmotors-pwa-installed', listener);
  return () {
    window.removeEventListener('iqmotors-pwa-installable', listener);
    window.removeEventListener('iqmotors-pwa-installed', listener);
  };
}
