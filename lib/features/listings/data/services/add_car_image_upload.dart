import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import 'package:iq_motors/core/platform/web_debug_log.dart';
import 'package:iq_motors/features/listings/domain/models/add_car_draft.dart';
import 'package:iq_motors/features/storage/data/services/r2_storage_service.dart';

/// Max parallel R2 uploads — avoids saturating the browser/native network stack
/// with several large payloads at once.
const int _maxConcurrentUploads = 3;

/// Uploads filled photo slots to R2 concurrently while preserving slot order.
/// Existing remote URLs (edit mode) are reused without re-uploading.
Future<List<String>> uploadCarImagesConcurrent(
  R2StorageService r2,
  List<String?> slots, {
  List<XFile?>? xFiles,
  Map<int, Uint8List>? previewBytesBySlot,
  int maxConcurrent = _maxConcurrentUploads,
}) async {
  final jobs = <Future<({int slotIndex, String url})> Function()>[];
  var uploadIndex = 0;

  for (var slotIndex = 0; slotIndex < slots.length; slotIndex++) {
    final slot = slots[slotIndex]?.trim();
    if (slot == null || slot.isEmpty) continue;

    if (AddCarDraft.isRemoteImageUrl(slot) && !slot.startsWith('blob:')) {
      final capturedIndex = slotIndex;
      final capturedUrl = slot;
      jobs.add(
        () async => (slotIndex: capturedIndex, url: capturedUrl),
      );
      continue;
    }

    final dotIndex = slot.lastIndexOf('.');
    final ext =
        dotIndex > 0 ? slot.substring(dotIndex).toLowerCase() : '.jpg';
    final uniqueName =
        '${DateTime.now().millisecondsSinceEpoch}_${slotIndex}_$uploadIndex$ext';
    uploadIndex++;

    final capturedIndex = slotIndex;
    final capturedPath = slot;
    final capturedXFile = xFiles?[slotIndex];
    final capturedBytes = previewBytesBySlot?[slotIndex];
    final capturedName = uniqueName;

    jobs.add(() async {
      try {
        final url = await r2.uploadPickedImage(
          path: capturedPath,
          xFile: capturedXFile,
          fileName: capturedName,
          bytes: capturedBytes,
        );
        return (slotIndex: capturedIndex, url: url);
      } catch (e, stackTrace) {
        webDebugLog('Upload failed for slot $capturedIndex: $e');
        webDebugLog('$stackTrace');
        rethrow;
      }
    });
  }

  if (jobs.isEmpty) return const [];

  final results = <({int slotIndex, String url})>[];
  final limit = maxConcurrent < 1 ? 1 : maxConcurrent;

  for (var i = 0; i < jobs.length; i += limit) {
    final batch = jobs.skip(i).take(limit).map((job) => job());
    // Batch keeps concurrency bounded so the UI isolate stays responsive.
    results.addAll(await Future.wait(batch));
  }

  results.sort((a, b) => a.slotIndex.compareTo(b.slotIndex));
  return results.map((r) => r.url).toList();
}
