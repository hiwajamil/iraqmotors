import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'admin_system_config.dart';

/// Resolved Cloudflare R2 settings (`.env` with optional Firestore overrides).
class R2Config {
  const R2Config({
    required this.endpointUrl,
    required this.accessKeyId,
    required this.secretAccessKey,
    required this.bucketName,
    required this.publicBaseUrl,
    this.region = 'auto',
  });

  final String endpointUrl;
  final String accessKeyId;
  final String secretAccessKey;
  final String bucketName;
  final String publicBaseUrl;
  final String region;

  static const defaultEndpointHost =
      'e5c493b87507d1d2efbeac09b1ee959d.r2.cloudflarestorage.com';
  static const defaultBucketName = 'iqmotors-media';

  /// Merges [admin] Firestore overrides on top of `.env` values.
  factory R2Config.resolve({AdminSystemConfig? admin}) {
    String env(String key) => dotenv.env[key]?.trim() ?? '';

    String pick(String adminValue, String envKey, {String fallback = ''}) {
      if (adminValue.trim().isNotEmpty) return adminValue.trim();
      final fromEnv = env(envKey);
      if (fromEnv.isNotEmpty) return fromEnv;
      return fallback;
    }

    final endpoint = pick(
      admin?.r2Endpoint ?? '',
      'R2_ENDPOINT_URL',
      fallback: 'https://$defaultEndpointHost',
    );

    return R2Config(
      endpointUrl: endpoint,
      accessKeyId: pick(admin?.r2AccessKey ?? '', 'R2_ACCESS_KEY_ID'),
      secretAccessKey: pick(admin?.r2SecretKey ?? '', 'R2_SECRET_ACCESS_KEY'),
      bucketName: pick(
        admin?.r2Bucket ?? '',
        'R2_BUCKET_NAME',
        fallback: defaultBucketName,
      ),
      publicBaseUrl: pick(admin?.r2PublicBaseUrl ?? '', 'R2_PUBLIC_BASE_URL'),
      region: pick(admin?.r2Region ?? '', 'R2_REGION', fallback: 'auto'),
    );
  }

  bool get hasCredentials =>
      accessKeyId.isNotEmpty && secretAccessKey.isNotEmpty;

  bool get hasPublicBaseUrl {
    final base = publicBaseUrl.trim();
    if (base.isEmpty) return false;
    if (base.contains('your-public-media-domain')) return false;
    if (base.contains('YOUR_R2_DEV_SUBDOMAIN')) return false;
    return true;
  }

  String get endpointHost {
    final uri = Uri.tryParse(endpointUrl);
    if (uri != null && uri.host.isNotEmpty) return uri.host;
    return defaultEndpointHost;
  }

  bool get useSsl {
    final scheme = Uri.tryParse(endpointUrl)?.scheme.toLowerCase();
    return scheme == null || scheme.isEmpty || scheme == 'https';
  }

  String get normalizedPublicBaseUrl =>
      publicBaseUrl.replaceAll(RegExp(r'/+$'), '');
}
