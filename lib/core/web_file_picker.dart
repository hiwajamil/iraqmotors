import 'picked_web_file.dart';
import 'web_file_picker_stub.dart'
    if (dart.library.html) 'web_file_picker_web.dart' as impl;

export 'picked_web_file.dart';

/// Opens a native browser file chooser on web; returns null on other platforms.
Future<PickedWebFile?> pickWebImageFile() => impl.pickWebImageFile();
