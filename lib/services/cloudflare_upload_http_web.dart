// Web-only implementation; imported via conditional import on web.
// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart';

import '../core/web_debug_log.dart';

@JS('iqMotorsUploadImageBase64')
external JSFunction? get _iqMotorsUploadImageBase64;

@JS('iqMotorsUploadImage')
external JSFunction? get _iqMotorsUploadImage;

/// Upload via browser `fetch` (index.html) with Dart fallbacks.
Future<({int statusCode, String body})> postImageBytes(
  Uri url,
  Uint8List bytes,
  String contentType,
) async {
  final payload = Uint8List.fromList(bytes);

  final jsResult = await _tryJsUploadBase64(payload);
  if (jsResult != null) return jsResult;

  final jsDirect = await _tryJsUploadDirect(payload);
  if (jsDirect != null) return jsDirect;

  webDebugLog('JS upload failed, trying Dart raw POST…');
  return _postRawBytes(url, payload, contentType);
}

Future<({int statusCode, String body})?> _tryJsUploadBase64(
  Uint8List bytes,
) async {
  final fn = _iqMotorsUploadImageBase64;
  if (fn == null) {
    webDebugLog('iqMotorsUploadImageBase64 not found');
    return null;
  }

  try {
    final b64 = base64Encode(bytes);
    webDebugLog('JS base64 upload ${bytes.length} bytes…');
    final raw = await (fn.callAsFunction(b64.toJS) as JSPromise<JSString>).toDart;
    return _parseJsUploadResult(raw.toDart);
  } catch (e) {
    webDebugLog('JS base64 upload error: $e');
  }
  return null;
}

Future<({int statusCode, String body})?> _tryJsUploadDirect(
  Uint8List bytes,
) async {
  final fn = _iqMotorsUploadImage;
  if (fn == null) return null;

  try {
    final raw =
        await (fn.callAsFunction(bytes.toJS) as JSPromise<JSString>).toDart;
    return _parseJsUploadResult(raw.toDart);
  } catch (e) {
    webDebugLog('JS direct upload error: $e');
  }
  return null;
}

({int statusCode, String body})? _parseJsUploadResult(String raw) {
  final map = jsonDecode(raw) as Map<String, dynamic>;
  final status = (map['status'] as num?)?.toInt() ?? 0;
  final body = map['body']?.toString() ?? '';
  final ok = map['ok'] == true;
  webDebugLog('JS upload status=$status ok=$ok');
  if (ok) return (statusCode: status, body: body);
  webDebugLog('JS upload failed: $body');
  return null;
}

Future<({int statusCode, String body})> _postRawBytes(
  Uri url,
  Uint8List bytes,
  String contentType,
) async {
  if (bytes.isEmpty) {
    throw Exception('Upload Error: empty image bytes');
  }

  webDebugLog('Raw POST ${bytes.length} bytes ($contentType)');
  // ignore: avoid_print
  print('Uploading image of size: ${bytes.lengthInBytes} bytes');

  final request = XMLHttpRequest();
  final done = Completer<({int statusCode, String body})>();
  late final JSFunction loadListener;
  late final JSFunction errorListener;

  loadListener = ((Event _) {
    done.complete((
      statusCode: request.status,
      body: request.responseText,
    ));
  }).toJS;

  errorListener = ((Event _) {
    if (!done.isCompleted) {
      done.completeError(Exception('Raw upload network error'));
    }
  }).toJS;

  request.addEventListener('load', loadListener);
  request.addEventListener('error', errorListener);
  request.open('POST', url.toString());
  request.setRequestHeader('Content-Type', contentType);
  request.send(bytes.toJS);

  try {
    return await done.future;
  } finally {
    request.removeEventListener('load', loadListener);
    request.removeEventListener('error', errorListener);
  }
}
