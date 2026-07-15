import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:minio/minio.dart';

import 'package:iq_motors/core/platform/image_upload_bytes.dart';
import 'package:iq_motors/features/storage/domain/models/r2_config.dart';
import 'package:iq_motors/features/storage/data/services/cloudflare_upload_service.dart';

class R2StorageException implements Exception {
  R2StorageException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Cloudflare R2 upload service (S3-compatible API via Minio client).
class R2StorageService {
  R2StorageService({
    R2Config? config,
    Minio? client,
    CloudflareUploadService? webUpload,
  })  : _config = config ?? R2Config.resolve(),
        _clientOverride = client,
        _webUpload = webUpload ?? CloudflareUploadService();

  final R2Config _config;
  final Minio? _clientOverride;
  final CloudflareUploadService _webUpload;
  Minio? _client;

  static const _objectPrefix = 'cars';

  String get _bucket => _config.bucketName;

  String get _publicBaseUrl {
    if (!_config.hasPublicBaseUrl) {
      throw R2StorageException(
        'R2_PUBLIC_BASE_URL is not configured. In Cloudflare: R2 → '
        'iqmotors-media → Settings → enable Public access (R2.dev), then set '
        'the https://pub-xxxx.r2.dev URL in .env or Admin → Security.',
      );
    }
    return _config.normalizedPublicBaseUrl;
  }

  Minio get _minio {
    if (!_config.hasCredentials) {
      throw R2StorageException(
        'R2 credentials are missing. Set R2_ACCESS_KEY_ID and '
        'R2_SECRET_ACCESS_KEY in .env or Admin → Security.',
      );
    }

    final override = _clientOverride;
    if (override != null) return override;
    return _client ??= Minio(
      endPoint: _config.endpointHost,
      accessKey: _config.accessKeyId,
      secretKey: _config.secretAccessKey,
      useSSL: _config.useSsl,
      region: _config.region,
      pathStyle: true,
    );
  }

  /// Uploads bytes to R2 and returns the public object URL.
  Future<String> uploadImageBytes(
    Uint8List bytes, {
    required String fileName,
    String? contentType,
  }) async {
    if (bytes.isEmpty) {
      throw R2StorageException(
        'Image byte array is empty! Cannot upload 0 bytes.',
      );
    }

    final prepared = await prepareImageBytesForUpload(bytes);
    if (prepared.isEmpty) {
      throw R2StorageException(
        'Image byte array is empty! Cannot upload 0 bytes.',
      );
    }

    final safeName = _jpegFileName(_sanitizeFileName(fileName));
    final objectKey = '$_objectPrefix/$safeName';
    const mime = 'image/jpeg';

    // ignore: avoid_print
    print('Uploading image of size: ${prepared.lengthInBytes} bytes');

    if (kIsWeb) {
      try {
        final url = await _webUpload.uploadImageToCloudflare(prepared, safeName);
        // ignore: avoid_print
        print('Successfully uploaded via worker: $url');
        return url;
      } on ImageModerationException {
        rethrow;
      } catch (e) {
        // ignore: avoid_print
        print('Error during web image upload: $e');
        throw R2StorageException('Upload failed: $e');
      }
    }

    try {
      await _minio.putObject(
        _bucket,
        objectKey,
        Stream<Uint8List>.value(prepared),
        size: prepared.length,
        metadata: {'Content-Type': mime},
      );
      final url = '$_publicBaseUrl/$objectKey';
      // ignore: avoid_print
      print('Successfully uploaded to R2: $url');
      return url;
    } on MinioError catch (e) {
      // ignore: avoid_print
      print('Error during image upload: $e');
      throw R2StorageException('Upload failed: ${e.message ?? e}');
    } catch (e) {
      // ignore: avoid_print
      print('Error during image upload: $e');
      if (e is R2StorageException) rethrow;
      throw R2StorageException('Upload failed: $e');
    }
  }

  /// Uploads a local [filePath] to R2 and returns the public object URL.
  Future<String> uploadImageFile(
    String filePath, {
    String? fileName,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw R2StorageException('Image file does not exist: $filePath');
    }

    final resolvedName = fileName ?? file.uri.pathSegments.last;
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw R2StorageException(
        'Image byte array is empty! Cannot upload 0 bytes.',
      );
    }

    return uploadImageBytes(bytes, fileName: resolvedName);
  }

  /// Uploads a gallery-picked image (native path or web blob URL).
  Future<String> uploadPickedImage({
    required String path,
    XFile? xFile,
    String? fileName,
    Uint8List? bytes,
  }) async {
    try {
      final picked = xFile ?? XFile(path);
      final resolvedName = fileName ?? picked.name;
      final imageBytes =
          bytes ?? await _readPickedImageBytes(picked, path: path);

      if (imageBytes.isEmpty) {
        throw R2StorageException(
          'Image byte array is empty! Cannot upload 0 bytes.',
        );
      }

      final mime = lookupMimeType(resolvedName) ?? 'image/jpeg';
      return await uploadImageBytes(
        imageBytes,
        fileName: resolvedName,
        contentType: mime,
      );
    } on ImageModerationException {
      rethrow;
    } on R2StorageException {
      rethrow;
    } catch (e) {
      // ignore: avoid_print
      print('Error during picked image upload: $e');
      throw R2StorageException('Upload failed: $e');
    }
  }

  /// Reads image bytes from [file] without relying on filesystem paths for upload.
  static Future<Uint8List> _readPickedImageBytes(
    XFile file, {
    required String path,
  }) async {
    try {
      final bytes = await file.readAsBytes();
      if (bytes.isNotEmpty) return bytes;
    } catch (e) {
      if (!kIsWeb) rethrow;
    }

    if (kIsWeb && path.startsWith('blob:')) {
      final response = await http.get(Uri.parse(path));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        return response.bodyBytes;
      }
      throw R2StorageException(
        'Failed to read blob URL (HTTP ${response.statusCode}).',
      );
    }

    return Uint8List(0);
  }

  /// Extracts the R2 object key from a public URL, or null if not managed by R2.
  String? objectKeyFromPublicUrl(String url) {
    if (_config.hasPublicBaseUrl) {
      final base = _config.normalizedPublicBaseUrl;
      if (url.startsWith(base)) {
        final path = url.substring(base.length).replaceFirst(RegExp(r'^/+'), '');
        return path.isEmpty ? null : path;
      }
    }

    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    final segments = uri.pathSegments;
    final carsIndex = segments.indexOf(_objectPrefix);
    if (carsIndex >= 0) {
      return segments.sublist(carsIndex).join('/');
    }
    return null;
  }

  /// Deletes objects in R2 for the given public [urls] (skips non-R2 URLs).
  Future<void> deleteImageUrls(List<String> urls) async {
    final keys = urls
        .map(objectKeyFromPublicUrl)
        .whereType<String>()
        .toSet()
        .toList();
    if (keys.isEmpty) return;

    try {
      await Future.wait(
        keys.map((key) => _minio.removeObject(_bucket, key)),
      );
    } on MinioError catch (e) {
      throw R2StorageException('Delete failed: ${e.message ?? e}');
    } catch (e) {
      if (e is R2StorageException) rethrow;
      throw R2StorageException('Delete failed: $e');
    }
  }

  /// Uploads multiple local image paths concurrently.
  Future<List<String>> uploadImagePaths(List<String> localPaths) async {
    final uploadable = localPaths.where(_isUploadableLocalPath).toList();
    if (uploadable.isEmpty) return const [];

    final urls = await Future.wait(
      uploadable.asMap().entries.map((entry) {
        final index = entry.key;
        final path = entry.value;
        final ext = _extensionFromPath(path);
        final uniqueName =
            '${DateTime.now().millisecondsSinceEpoch}_$index$ext';
        return uploadImageFile(path, fileName: uniqueName);
      }),
    );
    return urls;
  }

  static bool _isUploadableLocalPath(String path) {
    if (path.isEmpty) return false;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return false;
    }
    if (path.startsWith('simulated://')) return false;
    return true;
  }

  static String _jpegFileName(String fileName) {
    final dot = fileName.lastIndexOf('.');
    final stem = dot > 0 ? fileName.substring(0, dot) : fileName;
    return '$stem.jpg';
  }

  static String _sanitizeFileName(String fileName) {
    final safeName = fileName.trim().split(RegExp(r'[/\\]')).last;
    if (safeName.isEmpty || safeName == '.' || safeName == '..') {
      throw R2StorageException('Invalid file name.');
    }
    return safeName;
  }

  static String _extensionFromPath(String path) {
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex <= 0 || dotIndex >= path.length - 1) {
      return '.jpg';
    }
    return path.substring(dotIndex).toLowerCase();
  }
}
