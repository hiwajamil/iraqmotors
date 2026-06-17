// Web-only implementation; imported via conditional import on web.
// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart';

import 'picked_web_file.dart';

/// Last-resort web picker via hidden `<input type="file">`.
Future<PickedWebFile?> pickWebImageFile() async {
  final input = HTMLInputElement()
    ..type = 'file'
    ..accept = 'image/*';
  final completer = Completer<PickedWebFile?>();
  late final JSFunction changeListener;
  late final JSFunction focusListener;

  Future<void> finishWithFile(File file) async {
    if (completer.isCompleted) return;
    try {
      final bytes = await _readFileAsBytes(file);
      if (bytes.isEmpty) {
        completer.complete(null);
      } else {
        completer.complete(
          PickedWebFile(
            bytes: bytes,
            name: file.name.isNotEmpty ? file.name : 'photo.jpg',
          ),
        );
      }
    } catch (_) {
      if (!completer.isCompleted) completer.complete(null);
    } finally {
      input.removeEventListener('change', changeListener);
      window.removeEventListener('focus', focusListener);
      input.remove();
    }
  }

  void completeEmpty() {
    if (!completer.isCompleted) completer.complete(null);
    input.removeEventListener('change', changeListener);
    window.removeEventListener('focus', focusListener);
    input.remove();
  }

  changeListener = ((Event _) {
    final files = input.files;
    if (files == null || files.length == 0) {
      completeEmpty();
      return;
    }
    final file = files.item(0);
    if (file == null) {
      completeEmpty();
      return;
    }
    finishWithFile(file);
  }).toJS;

  focusListener = ((Event _) {
    // CanvasKit sometimes misses onChange; poll after the dialog closes.
    Future<void>.delayed(const Duration(milliseconds: 300), () async {
      if (completer.isCompleted) return;
      final files = input.files;
      if (files != null && files.length > 0) {
        final file = files.item(0);
        if (file != null) {
          await finishWithFile(file);
        } else {
          Future<void>.delayed(const Duration(milliseconds: 400), () {
            if (!completer.isCompleted) completeEmpty();
          });
        }
      } else {
        Future<void>.delayed(const Duration(milliseconds: 400), () {
          if (!completer.isCompleted) completeEmpty();
        });
      }
    });
  }).toJS;

  input.addEventListener('change', changeListener);
  document.body?.append(input);
  input.click();
  window.addEventListener('focus', focusListener);

  try {
    return await completer.future;
  } finally {
    input.removeEventListener('change', changeListener);
    window.removeEventListener('focus', focusListener);
  }
}

Future<Uint8List> _readFileAsBytes(File file) async {
  try {
    final buffer = await file.arrayBuffer().toDart;
    return Uint8List.view(buffer.toDart);
  } catch (_) {
    return Uint8List(0);
  }
}
