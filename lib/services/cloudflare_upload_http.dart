import 'dart:typed_data';

import 'package:http/http.dart' as http;

Future<({int statusCode, String body})> postImageBytes(
  Uri url,
  Uint8List bytes,
  String contentType,
) async {
  if (bytes.isEmpty) {
    throw Exception('Upload Error: empty image bytes');
  }

  // ignore: avoid_print
  print('Uploading image of size: ${bytes.lengthInBytes} bytes');

  final request = http.Request('POST', url);
  request.headers['Content-Type'] = contentType;
  request.bodyBytes = bytes;

  final streamedResponse = await request.send();
  final response = await http.Response.fromStream(streamedResponse);
  return (statusCode: response.statusCode, body: response.body);
}
