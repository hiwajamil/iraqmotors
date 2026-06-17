import 'web_pick_upload_result.dart';
import 'web_pick_upload_stub.dart'
    if (dart.library.html) 'web_pick_upload_web.dart' as impl;

export 'web_pick_upload_result.dart';

/// Opens the OS file dialog and uploads to the Cloudflare Worker (web only).
Future<WebPickUploadResult> startWebPickAndUpload() =>
    impl.startWebPickAndUpload();
