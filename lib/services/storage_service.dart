import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:minio/io.dart';
import 'package:minio/minio.dart';

class StorageException implements Exception {
  StorageException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Uploads car images to Cloudflare R2 (S3-compatible API).
class StorageService {
  StorageService({Minio? client}) : _clientOverride = client;

  final Minio? _clientOverride;
  Minio? _client;

  static const _objectPrefix = 'cars';

  String _requireEnv(String key) {
    final value = dotenv.env[key]?.trim();
    if (value == null || value.isEmpty) {
      throw StorageException(
        'Missing $key in .env. Copy .env.example and fill in your R2 values.',
      );
    }
    return value;
  }

  String get _bucket => _requireEnv('R2_BUCKET_NAME');

  String get _accessKey => _requireEnv('R2_ACCESS_KEY_ID');

  String get _secretKey => _requireEnv('R2_SECRET_ACCESS_KEY');

  String get _endpointHost {
    final raw = _requireEnv('R2_ENDPOINT_URL');
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.host.isEmpty) {
      throw StorageException('R2_ENDPOINT_URL is not a valid URL.');
    }
    return uri.host;
  }

  bool get _useSsl {
    final raw = _requireEnv('R2_ENDPOINT_URL');
    final scheme = Uri.tryParse(raw)?.scheme.toLowerCase();
    return scheme == null || scheme.isEmpty || scheme == 'https';
  }

  String get _region => dotenv.env['R2_REGION']?.trim() ?? 'auto';

  String get _publicBaseUrl {
    final base = _requireEnv('R2_PUBLIC_BASE_URL');
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

  /// Uploads [imageFile] to R2 under `cars/<fileName>` and returns the public URL.
  Future<String> uploadCarImage(File imageFile, String fileName) async {
    if (!await imageFile.exists()) {
      throw StorageException('Image file does not exist.');
    }

    final safeName = fileName.trim().split(RegExp(r'[/\\]')).last;
    if (safeName.isEmpty || safeName == '.' || safeName == '..') {
      throw StorageException('Invalid file name.');
    }

    final objectKey = '$_objectPrefix/$safeName';

    try {
      await _minio.fPutObject(_bucket, objectKey, imageFile.path);
    } on MinioError catch (e) {
      throw StorageException('Upload failed: ${e.message ?? e}');
    } catch (e) {
      throw StorageException('Upload failed: $e');
    }

    return '$_publicBaseUrl/$objectKey';
  }
}
