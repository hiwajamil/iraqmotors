import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../core/image_upload_bytes.dart';
import '../core/web_debug_log.dart';
import 'cloudflare_upload_http.dart'
    if (dart.library.html) 'cloudflare_upload_http_web.dart' as upload_http;

/// Uploads car listing images via the Cloudflare Worker proxy (avoids browser CORS).
class CloudflareUploadService {
  static const String cloudflareWorkerUrl =
      'https://iqmotors-upload-api.hiwa-constructions.workers.dev/';

  /// Sends [imageBytes] to the worker and returns the public R2 URL on success.
  Future<String> uploadImageToCloudflare(
    Uint8List imageBytes,
    String fileName,
  ) async {
    if (imageBytes.isEmpty) {
      throw Exception('Upload Error: empty image bytes');
    }

    final prepared = await prepareImageBytesForUpload(imageBytes);
    if (prepared.isEmpty) {
      throw Exception(
        'Image byte array is empty! Cannot upload 0 bytes.',
      );
    }
    const contentType = 'image/jpeg';

    // ignore: avoid_print
    print('Uploading image of size: ${prepared.lengthInBytes} bytes');
    webDebugLog(
      'POST ${prepared.length} bytes (${_jpegFileName(fileName)}) to worker…',
    );

    final response = await upload_http.postImageBytes(
      Uri.parse(cloudflareWorkerUrl),
      prepared,
      contentType,
    );

    final body = response.body.trim();
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        body.isEmpty) {
      throw Exception('Upload Error: HTTP ${response.statusCode} — $body');
    }

    final json = jsonDecode(body) as Map<String, dynamic>;
    if (json['success'] == true && json['url'] is String) {
      final url = (json['url'] as String).trim();
      if (url.isNotEmpty) return url;
    }

    throw Exception('Upload Error: unexpected response — $body');
  }

  static String _jpegFileName(String fileName) {
    final dot = fileName.lastIndexOf('.');
    final stem = dot > 0 ? fileName.substring(0, dot) : fileName;
    return '$stem.jpg';
  }
}
