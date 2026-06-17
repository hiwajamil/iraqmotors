import 'dart:convert';
import 'dart:js_interop';

import 'web_debug_log.dart';
import 'web_pick_upload_result.dart';

@JS('iqMotorsPickAndUploadImage')
external JSFunction? get _iqMotorsPickAndUploadImage;

Future<WebPickUploadResult> startWebPickAndUpload() async {
  final fn = _iqMotorsPickAndUploadImage;
  if (fn == null) {
    webDebugLog('iqMotorsPickAndUploadImage missing');
    return const WebPickUploadResult(ok: false, error: 'upload js missing');
  }

  try {
    webDebugLog('Starting JS pick+upload…');
    final raw = await (fn.callAsFunction() as JSPromise<JSString>).toDart;
    final map = jsonDecode(raw.toDart) as Map<String, dynamic>;
    final ok = map['ok'] == true;
    final url = map['url']?.toString();
    final error = map['error']?.toString();
    final cancelled = map['cancelled'] == true;
    webDebugLog('JS pick+upload ok=$ok url=$url error=$error');
    return WebPickUploadResult(
      ok: ok,
      url: url,
      error: error,
      cancelled: cancelled,
    );
  } catch (e) {
    webDebugLog('JS pick+upload error: $e');
    return WebPickUploadResult(ok: false, error: e.toString());
  }
}
