import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Max edge length for in-wizard photo previews (display + upload source).
const int addCarPreviewMaxEdge = 1600;

/// Max edge length for photos sent to Gemini (smaller payload, faster API).
const int addCarAiVisionMaxEdge = 1024;

/// JPEG quality for wizard preview bytes held in memory.
const int addCarPreviewJpegQuality = 85;

/// JPEG quality for AI vision requests.
const int addCarAiVisionJpegQuality = 78;

/// Prepares picked photo bytes off the UI thread for preview/upload slots.
Future<Uint8List> prepareAddCarPreviewBytes(Uint8List raw) {
  if (raw.isEmpty) return Future.value(raw);
  return compute(
    _encodePreviewBytes,
    _ImageProcessRequest(
      raw,
      maxEdge: addCarPreviewMaxEdge,
      quality: addCarPreviewJpegQuality,
    ),
  );
}

/// Compresses/resizes photos off the UI thread before Gemini analysis.
Future<Uint8List> prepareAddCarAiVisionBytes(Uint8List raw) {
  if (raw.isEmpty) return Future.value(raw);
  return compute(
    _encodePreviewBytes,
    _ImageProcessRequest(
      raw,
      maxEdge: addCarAiVisionMaxEdge,
      quality: addCarAiVisionJpegQuality,
    ),
  );
}

/// Batch-prepares multiple images for AI (one isolate call per image, parallel).
Future<List<Uint8List>> prepareAddCarAiVisionBatch(List<Uint8List> raws) {
  return Future.wait(raws.map(prepareAddCarAiVisionBytes));
}

class _ImageProcessRequest {
  const _ImageProcessRequest(
    this.bytes, {
    required this.maxEdge,
    required this.quality,
  });

  final Uint8List bytes;
  final int maxEdge;
  final int quality;
}

Uint8List _encodePreviewBytes(_ImageProcessRequest request) {
  try {
    final decoded = img.decodeImage(request.bytes);
    if (decoded == null) return request.bytes;

    final longest = decoded.width > decoded.height
        ? decoded.width
        : decoded.height;
    final img.Image processed;
    if (longest > request.maxEdge) {
      processed = img.copyResize(
        decoded,
        width: decoded.width >= decoded.height ? request.maxEdge : null,
        height: decoded.height > decoded.width ? request.maxEdge : null,
        interpolation: img.Interpolation.average,
      );
    } else {
      processed = decoded;
    }

    return Uint8List.fromList(
      img.encodeJpg(processed, quality: request.quality),
    );
  } catch (_) {
    return request.bytes;
  }
}
