import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import 'package:iq_motors/features/listings/domain/models/add_car_draft.dart';
import 'package:iq_motors/features/storage/data/services/r2_storage_service.dart';

/// Uploads filled photo slots to R2 concurrently while preserving slot order.
/// Existing remote URLs (edit mode) are reused without re-uploading.
Future<List<String>> uploadCarImagesConcurrent(
  R2StorageService r2,
  List<String?> slots, {
  List<XFile?>? xFiles,
  Map<int, Uint8List>? previewBytesBySlot,
}) async {
  final tasks = <Future<({int slotIndex, String url})>>[];
  var uploadIndex = 0;

  for (var slotIndex = 0; slotIndex < slots.length; slotIndex++) {
    final slot = slots[slotIndex]?.trim();
    if (slot == null || slot.isEmpty) continue;

    if (AddCarDraft.isRemoteImageUrl(slot) && !slot.startsWith('blob:')) {
      tasks.add(
        Future.value((slotIndex: slotIndex, url: slot)),
      );
      continue;
    }

    final dotIndex = slot.lastIndexOf('.');
    final ext =
        dotIndex > 0 ? slot.substring(dotIndex).toLowerCase() : '.jpg';
    final uniqueName =
        '${DateTime.now().millisecondsSinceEpoch}_${slotIndex}_$uploadIndex$ext';
    uploadIndex++;

    tasks.add(
      r2
          .uploadPickedImage(
            path: slot,
            xFile: xFiles?[slotIndex],
            fileName: uniqueName,
            bytes: previewBytesBySlot?[slotIndex],
          )
          .then((url) => (slotIndex: slotIndex, url: url)),
    );
  }

  if (tasks.isEmpty) return const [];

  final results = await Future.wait(tasks);
  results.sort((a, b) => a.slotIndex.compareTo(b.slotIndex));
  return results.map((r) => r.url).toList();
}
