import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:minio/io.dart';
import 'package:minio/minio.dart';

import '../models/r2_config.dart';

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
  })  : _config = config ?? R2Config.resolve(),
        _clientOverride = client;

  final R2Config _config;
  final Minio? _clientOverride;
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
    final safeName = _sanitizeFileName(fileName);
    final objectKey = '$_objectPrefix/$safeName';
    final mime = contentType ?? lookupMimeType(safeName) ?? 'image/jpeg';

    try {
      await _minio.putObject(
        _bucket,
        objectKey,
        Stream<Uint8List>.value(bytes),
        size: bytes.length,
        metadata: {'Content-Type': mime},
      );
    } on MinioError catch (e) {
      throw R2StorageException('Upload failed: ${e.message ?? e}');
    } catch (e) {
      if (e is R2StorageException) rethrow;
      throw R2StorageException('Upload failed: $e');
    }

    return '$_publicBaseUrl/$objectKey';
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
    final safeName = _sanitizeFileName(resolvedName);
    final objectKey = '$_objectPrefix/$safeName';

    try {
      await _minio.fPutObject(_bucket, objectKey, file.path);
    } on MinioError catch (e) {
      throw R2StorageException('Upload failed: ${e.message ?? e}');
    } catch (e) {
      if (e is R2StorageException) rethrow;
      throw R2StorageException('Upload failed: $e');
    }

    return '$_publicBaseUrl/$objectKey';
  }

  /// Uploads a gallery-picked image (native path or web blob URL).
  Future<String> uploadPickedImage({
    required String path,
    XFile? xFile,
    String? fileName,
  }) async {
    if (!kIsWeb && !path.startsWith('blob:')) {
      final file = File(path);
      if (await file.exists()) {
        return uploadImageFile(path, fileName: fileName);
      }
    }

    final picked = xFile ?? XFile(path);
    final bytes = await picked.readAsBytes();
    final resolvedName = fileName ?? picked.name;
    final mime = lookupMimeType(resolvedName) ?? 'image/jpeg';

    return uploadImageBytes(
      bytes,
      fileName: resolvedName,
      contentType: mime,
    );
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
