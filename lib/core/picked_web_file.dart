import 'dart:typed_data';

/// A user-selected image file (bytes + name) from a web file input.
class PickedWebFile {
  const PickedWebFile({required this.bytes, required this.name});

  final Uint8List bytes;
  final String name;
}
