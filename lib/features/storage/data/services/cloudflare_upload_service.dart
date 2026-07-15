import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:iq_motors/core/platform/web_debug_log.dart';
import 'package:iq_motors/features/storage/data/services/cloudflare_upload_http.dart'
    if (dart.library.html) 'package:iq_motors/features/storage/data/services/cloudflare_upload_http_web.dart' as upload_http;

/// Thrown when the upload worker rejects an image after AI moderation (HTTP 400).
class ImageModerationException implements Exception {
  ImageModerationException(this.reason);

  final String reason;

  @override
  String toString() => reason;
}

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

    const contentType = 'image/jpeg';

    // ignore: avoid_print
    print('Uploading image of size: ${imageBytes.lengthInBytes} bytes');
    webDebugLog('POST ${imageBytes.length} bytes ($fileName) to worker…');

    try {
      final response = await upload_http.postImageBytes(
        Uri.parse(cloudflareWorkerUrl),
        imageBytes,
        contentType,
      );

      final body = response.body.trim();
      if (response.statusCode == 400) {
        throw _moderationExceptionFromBody(body);
      }
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
    } on ImageModerationException {
      rethrow;
    } catch (e) {
      webDebugLog('Cloudflare upload failed: $e');
      rethrow;
    }
  }

  static ImageModerationException _moderationExceptionFromBody(String body) {
    if (body.isNotEmpty) {
      try {
        final json = jsonDecode(body) as Map<String, dynamic>;
        final reason = json['reason'];
        if (reason is String && reason.trim().isNotEmpty) {
          return ImageModerationException(reason.trim());
        }
        final error = json['error'];
        if (error is String && error.trim().isNotEmpty) {
          return ImageModerationException(error.trim());
        }
      } catch (_) {
        // Fall through to generic message below.
      }
    }
    return ImageModerationException(
      'وێنەکە قبوڵ نەکرا. تکایە وێنەیەکی تر هەڵبژێرە.',
    );
  }

}
