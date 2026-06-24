// Web-only implementation; imported via conditional import on web.
// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:js_interop';

import 'package:web/web.dart';

void webDebugLog(String message) {
  console.log('[IQ Motors] $message'.toJS);
}
