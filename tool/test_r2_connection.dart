import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:minio/minio.dart';

/// Verifies R2 credentials, lists recent uploads, and probes public URL bases.
///
/// Run: dart run tool/test_r2_connection.dart
Future<void> main() async {
  await dotenv.load(fileName: '.env');

  final accessKey = dotenv.env['R2_ACCESS_KEY_ID']?.trim() ?? '';
  final secretKey = dotenv.env['R2_SECRET_ACCESS_KEY']?.trim() ?? '';
  final bucket = dotenv.env['R2_BUCKET_NAME']?.trim() ?? 'iqmotors-media';
  final endpointRaw =
      dotenv.env['R2_ENDPOINT_URL']?.trim() ??
      'https://e5c493b87507d1d2efbeac09b1ee959d.r2.cloudflarestorage.com';
  final configuredPublic = dotenv.env['R2_PUBLIC_BASE_URL']?.trim() ?? '';

  final endpointHost = Uri.parse(endpointRaw).host;

  if (accessKey.isEmpty || secretKey.isEmpty) {
    stderr.writeln('Missing R2_ACCESS_KEY_ID or R2_SECRET_ACCESS_KEY in .env');
    exit(1);
  }

  final minio = Minio(
    endPoint: endpointHost,
    accessKey: accessKey,
    secretKey: secretKey,
    useSSL: true,
    region: dotenv.env['R2_REGION']?.trim() ?? 'auto',
    pathStyle: true,
  );

  stdout.writeln('R2 endpoint: $endpointHost');
  stdout.writeln('Bucket: $bucket');
  stdout.writeln('Configured public base: $configuredPublic');
  stdout.writeln('');

  try {
    final stream = minio.listObjectsV2(bucket, prefix: 'cars/', recursive: true);
    var count = 0;
    String? sampleKey;
    await for (final batch in stream) {
      for (final raw in batch.objects) {
        final key = (raw as dynamic).key as String?;
        final size = (raw as dynamic).size as int?;
        count++;
        sampleKey ??= key;
        if (count <= 5) {
          stdout.writeln('  object: $key (${size ?? 0} bytes)');
        }
      }
    }
    stdout.writeln('Listed $count object(s) under cars/');
    stdout.writeln('');

    final testKey = 'cars/_connection_test_${DateTime.now().millisecondsSinceEpoch}.txt';
    final payload = Uint8List.fromList('iqmotors-r2-test'.codeUnits);
    await minio.putObject(
      bucket,
      testKey,
      Stream.value(payload),
      size: payload.length,
      metadata: {'Content-Type': 'text/plain'},
    );
    stdout.writeln('Upload test OK: $testKey');

    final probeKeys = <String>{
      ?sampleKey,
      testKey,
    };

    final probeBases = <String>{
      if (configuredPublic.isNotEmpty &&
          !configuredPublic.contains('your-public-media-domain') &&
          !configuredPublic.contains('YOUR_R2_DEV_SUBDOMAIN'))
        configuredPublic.replaceAll(RegExp(r'/+$'), ''),
      'https://media.iqmotors.net',
      'https://cdn.iqmotors.net',
      'https://images.iqmotors.net',
    };

    stdout.writeln('');
    stdout.writeln('Probing public URLs...');
    for (final base in probeBases) {
      for (final key in probeKeys) {
        final url = '$base/$key';
        final client = HttpClient();
        try {
          final request = await client.headUrl(Uri.parse(url));
          final response = await request.close();
          stdout.writeln(
            '  ${response.statusCode} $url',
          );
          if (response.statusCode == 200) {
            stdout.writeln('');
            stdout.writeln('WORKING PUBLIC BASE URL: $base');
            stdout.writeln('Set in .env: R2_PUBLIC_BASE_URL=$base');
            client.close(force: true);
            return;
          }
        } catch (e) {
          stdout.writeln('  ERR $url ($e)');
        } finally {
          client.close(force: true);
        }
      }
    }

    stdout.writeln('');
    stdout.writeln(
      'Could not auto-detect public URL. Enable R2.dev public access in '
      'Cloudflare dashboard and set R2_PUBLIC_BASE_URL in .env.',
    );
  } on MinioError catch (e) {
    stderr.writeln('R2 error: ${e.message ?? e}');
    exit(1);
  } catch (e) {
    stderr.writeln('Error: $e');
    exit(1);
  }
}
