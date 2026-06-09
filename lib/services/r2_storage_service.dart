import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:minio/io.dart';
import 'package:minio/minio.dart';

class R2StorageException implements Exception {
  R2StorageException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Cloudflare R2 upload service (S3-compatible API via Minio client).
class R2StorageService {
  R2StorageService({Minio? client}) : _clientOverride = client;

  final Minio? _clientOverride;
  Minio? _client;

  static const _objectPrefix = 'cars';

  // Default R2 credentials — override via `.env` when available.
  static const _defaultEndpointHost =
      'e5c493b87507d1d2efbeac09b1ee959d.r2.cloudflarestorage.com';
  static const _defaultRegion = 'auto';
  static const _defaultAccessKeyId = '8b7cb47968648404a58c718723d9eeb9';
  static const _defaultSecretAccessKey =
      'f9ede02ddf10a0f5934da9aa52ee4186d0e3800399f77a61aec4f65c292b29ed';
  static const _defaultBucketName = 'iqmotors-media';
  static const _defaultPublicBaseUrl =
      'https://pub-YOUR_R2_DEV_SUBDOMAIN.r2.dev';

  String _envOrDefault(String key, String fallback) {
    final value = dotenv.env[key]?.trim();
    if (value != null && value.isNotEmpty) return value;
    return fallback;
  }

  String get _bucket => _envOrDefault('R2_BUCKET_NAME', _defaultBucketName);

  String get _accessKey =>
      _envOrDefault('R2_ACCESS_KEY_ID', _defaultAccessKeyId);

  String get _secretKey =>
      _envOrDefault('R2_SECRET_ACCESS_KEY', _defaultSecretAccessKey);

  String get _endpointHost {
    final raw = _envOrDefault(
      'R2_ENDPOINT_URL',
      'https://$_defaultEndpointHost',
    );
    final uri = Uri.tryParse(raw);
    if (uri != null && uri.host.isNotEmpty) return uri.host;
    return _defaultEndpointHost;
  }

  bool get _useSsl {
    final raw = _envOrDefault(
      'R2_ENDPOINT_URL',
      'https://$_defaultEndpointHost',
    );
    final scheme = Uri.tryParse(raw)?.scheme.toLowerCase();
    return scheme == null || scheme.isEmpty || scheme == 'https';
  }

  String get _region => _envOrDefault('R2_REGION', _defaultRegion);

  String get _publicBaseUrl {
    final base = _envOrDefault('R2_PUBLIC_BASE_URL', _defaultPublicBaseUrl);
    return base.replaceAll(RegExp(r'/+$'), '');
  }

  Minio get _minio {
    final override = _clientOverride;
    if (override != null) return override;
    return _client ??= Minio(
      endPoint: _endpointHost,
      accessKey: _accessKey,
      secretKey: _secretKey,
      useSSL: _useSsl,
      region: _region,
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
    final base = _publicBaseUrl;
    if (url.startsWith(base)) {
      final path = url.substring(base.length).replaceFirst(RegExp(r'^/+'), '');
      return path.isEmpty ? null : path;
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
