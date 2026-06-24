import 'package:iq_motors/core/platform/picked_web_file.dart';
import 'package:iq_motors/core/platform/web_file_picker_stub.dart'
    if (dart.library.html) 'package:iq_motors/core/platform/web_file_picker_web.dart' as impl;

export 'package:iq_motors/core/platform/picked_web_file.dart';

/// Opens a native browser file chooser on web; returns null on other platforms.
Future<PickedWebFile?> pickWebImageFile() => impl.pickWebImageFile();
