import 'dart:typed_data';

import 'package:http/http.dart' as http;

Future<({int statusCode, String body})> postImageBytes(
  Uri url,
  Uint8List bytes,
  String contentType,
) async {
  final response = await http.post(
    url,
    headers: {'Content-Type': contentType},
    body: bytes,
  );
  return (statusCode: response.statusCode, body: response.body);
}
