import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;

import 'package:iq_motors/core/platform/web_debug_log.dart';

import 'package:iq_motors/core/services/firebase_performance_service.dart';

const _maxDimension = 1920;
const _jpegQuality = 82;

/// Resizes and re-encodes as JPEG (~250KB target) before upload.
Future<Uint8List> prepareImageBytesForUpload(Uint8List raw) async {
  if (raw.isEmpty) return raw;

  // Already small enough — skip re-encode.
  if (raw.length < 250 * 1024) return raw;

  return FirebasePerformanceService.instance.traceAsync(
    'prepareImageBytesForUpload',
    () async {
      try {
        final compressed = await FlutterImageCompress.compressWithList(
          raw,
          minWidth: _maxDimension,
          minHeight: _maxDimension,
          quality: _jpegQuality,
          format: CompressFormat.jpeg,
        );
        if (compressed.isNotEmpty) {
          webDebugLog('Compressed ${raw.length} → ${compressed.length} bytes');
          return compressed;
        }

        return _compressWithImagePackage(raw);
      } catch (e) {
        webDebugLog('Image compression skipped: $e');
        return _compressWithImagePackage(raw);
      }
    },
    metrics: {'original_bytes': raw.length},
  );
}

Uint8List _compressWithImagePackage(Uint8List raw) {
  try {
    final decoded = img.decodeImage(raw);
    if (decoded == null) {
      webDebugLog('Image decode returned null — uploading original bytes');
      return raw;
    }

    final resized = decoded.width > _maxDimension || decoded.height > _maxDimension
        ? img.copyResize(
            decoded,
            width: decoded.width >= decoded.height ? _maxDimension : null,
            height: decoded.height > decoded.width ? _maxDimension : null,
          )
        : decoded;

    final jpeg = Uint8List.fromList(img.encodeJpg(resized, quality: _jpegQuality));
    webDebugLog('Compressed ${raw.length} → ${jpeg.length} bytes (image pkg)');
    return jpeg;
  } catch (e) {
    webDebugLog('Image package compression skipped: $e');
    return raw;
  }
}
