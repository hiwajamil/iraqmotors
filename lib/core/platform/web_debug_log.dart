import 'package:iq_motors/core/platform/web_debug_log_stub.dart'
    if (dart.library.html) 'package:iq_motors/core/platform/web_debug_log_web.dart' as impl;

/// Logs to the browser DevTools console (visible in release web builds).
void webDebugLog(String message) => impl.webDebugLog(message);
