import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:iq_motors/core/platform/web_debug_log.dart';
import 'package:iq_motors/features/listings/data/services/add_car_image_upload.dart';
import 'package:iq_motors/features/listings/domain/models/add_car_draft.dart';
import 'package:iq_motors/features/marketplace/data/services/car_database_service.dart';
import 'package:iq_motors/features/storage/data/services/r2_storage_service.dart';
import 'package:iq_motors/features/storage/presentation/providers/r2_storage_provider.dart';
import 'package:iq_motors/features/storage/presentation/providers/storage_providers.dart';
import 'package:iq_motors/shared/models/car_brand.dart';

/// Wizard session parameters passed when opening [AddCarFlowScreen].
class AddCarFlowSession {
  const AddCarFlowSession({
    this.existingAdId,
    this.existingCarData,
    this.initialStep = 0,
    this.isDraft = false,
  });

  final String? existingAdId;
  final Map<String, dynamic>? existingCarData;
  final int initialStep;
  final bool isDraft;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AddCarFlowSession &&
          existingAdId == other.existingAdId &&
          initialStep == other.initialStep &&
          isDraft == other.isDraft &&
          mapEquals(existingCarData, other.existingCarData);

  @override
  int get hashCode => Object.hash(
        existingAdId,
        initialStep,
        isDraft,
        existingCarData == null
            ? null
            : Object.hashAll(existingCarData!.entries),
      );
}

/// In-memory wizard state. Intermediate steps never touch the network.
class AddCarFlowState {
  const AddCarFlowState({
    required this.draft,
    this.currentStep = 0,
    this.isPublishing = false,
    this.isSavingDraft = false,
    this.uploadingPhotoSlots = const {},
    this.slotPreviewBytes = const {},
    this.selectedImages = const [],
    this.aiFilledFields = const {},
    this.isAnalyzingAi = false,
    this.draftAdId,
    this.existingAdId,
    this.isDraftMode = false,
  });

  static const int stepCount = 12;

  final AddCarDraft draft;
  final int currentStep;
  final bool isPublishing;
  final bool isSavingDraft;
  final Set<int> uploadingPhotoSlots;
  final Map<int, Uint8List> slotPreviewBytes;
  final List<XFile?> selectedImages;
  final Set<String> aiFilledFields;
  final bool isAnalyzingAi;
  final String? draftAdId;
  final String? existingAdId;
  final bool isDraftMode;

  bool get isEditMode => existingAdId != null && !isDraftMode;

  bool get isAnyPhotoUploading => uploadingPhotoSlots.isNotEmpty;

  bool get canProceed {
    switch (currentStep) {
      case 0:
        return draft.isLocationComplete;
      case 1:
        return draft.hasMinimumPhotos;
      case 2:
        return draft.isBasicInfoComplete;
      case 3:
        return draft.isPlateInfoComplete;
      case 4:
        return draft.isMileageFuelComplete;
      case 5:
        return draft.isTechnicalComplete;
      case 6:
        return draft.isInteriorComplete;
      case 7:
        return draft.isConditionFeaturesComplete;
      case 8:
        return draft.isPriceDescriptionComplete;
      case 9:
        return draft.isReviewComplete;
      case 10:
        return draft.isPackageComplete;
      case 11:
        return draft.isPaymentComplete;
      default:
        return false;
    }
  }

  AddCarFlowState copyWith({
    AddCarDraft? draft,
    int? currentStep,
    bool? isPublishing,
    bool? isSavingDraft,
    Set<int>? uploadingPhotoSlots,
    Map<int, Uint8List>? slotPreviewBytes,
    List<XFile?>? selectedImages,
    Set<String>? aiFilledFields,
    bool? isAnalyzingAi,
    String? draftAdId,
  }) {
    return AddCarFlowState(
      draft: draft ?? this.draft,
      currentStep: currentStep ?? this.currentStep,
      isPublishing: isPublishing ?? this.isPublishing,
      isSavingDraft: isSavingDraft ?? this.isSavingDraft,
      uploadingPhotoSlots: uploadingPhotoSlots ?? this.uploadingPhotoSlots,
      slotPreviewBytes: slotPreviewBytes ?? this.slotPreviewBytes,
      selectedImages: selectedImages ?? this.selectedImages,
      aiFilledFields: aiFilledFields ?? this.aiFilledFields,
      isAnalyzingAi: isAnalyzingAi ?? this.isAnalyzingAi,
      draftAdId: draftAdId ?? this.draftAdId,
      existingAdId: existingAdId,
      isDraftMode: isDraftMode,
    );
  }

  factory AddCarFlowState.initial(AddCarFlowSession session) {
    final draft = session.existingCarData != null
        ? AddCarDraft.fromFirestoreMap(session.existingCarData!)
        : const AddCarDraft();

    return AddCarFlowState(
      draft: draft,
      currentStep: session.initialStep.clamp(0, stepCount - 1),
      selectedImages: List<XFile?>.filled(AddCarDraft.photoSlotCount, null),
      draftAdId: session.isDraft && session.existingAdId != null
          ? session.existingAdId
          : null,
      existingAdId: session.existingAdId,
      isDraftMode: session.isDraft,
    );
  }
}

final addCarFlowProvider = NotifierProvider.autoDispose
    .family<AddCarFlowNotifier, AddCarFlowState, AddCarFlowSession>(
  AddCarFlowNotifier.new,
);

class AddCarFlowNotifier extends Notifier<AddCarFlowState> {
  AddCarFlowNotifier(this._session);

  final AddCarFlowSession _session;

  @override
  AddCarFlowState build() => AddCarFlowState.initial(_session);

  /// Advances one step synchronously (no network I/O).
  void goNext() {
    if (!state.canProceed || state.isPublishing || state.isAnyPhotoUploading) {
      return;
    }
    if (state.currentStep >= AddCarFlowState.stepCount - 1) return;
    goToStep(state.currentStep + 1);
  }

  void goToStep(int step) {
    state = state.copyWith(
      currentStep: step.clamp(0, AddCarFlowState.stepCount - 1),
    );
  }

  void updateDraft(AddCarDraft draft) {
    state = state.copyWith(draft: draft);
  }

  void setPublishing(bool value) {
    state = state.copyWith(isPublishing: value);
  }

  void setSavingDraft(bool value) {
    state = state.copyWith(isSavingDraft: value);
  }

  void setAnalyzingAi(bool value) {
    state = state.copyWith(isAnalyzingAi: value);
  }

  void addUploadingSlot(int index) {
    state = state.copyWith(
      uploadingPhotoSlots: {...state.uploadingPhotoSlots, index},
    );
  }

  void removeUploadingSlot(int index) {
    final next = Set<int>.from(state.uploadingPhotoSlots)..remove(index);
    state = state.copyWith(uploadingPhotoSlots: next);
  }

  void assignPhotoToSlot(
    int index,
    XFile picked,
    Uint8List imageBytes,
  ) {
    final slots = state.draft.normalizedPhotos();
    final selectedImages = List<XFile?>.from(state.selectedImages);
    final previewBytes = Map<int, Uint8List>.from(state.slotPreviewBytes);
    final uploading = Set<int>.from(state.uploadingPhotoSlots)..remove(index);

    selectedImages[index] = picked;
    previewBytes[index] = imageBytes;

    state = state.copyWith(
      uploadingPhotoSlots: uploading,
      selectedImages: selectedImages,
      slotPreviewBytes: previewBytes,
      draft: state.draft.copyWith(
        photos: List<String?>.from(slots)..[index] = picked.path,
      ),
    );
  }

  void removePhotoSlot(int index) {
    final slots = List<String?>.from(state.draft.normalizedPhotos());
    slots[index] = null;

    final selectedImages = List<XFile?>.from(state.selectedImages);
    selectedImages[index] = null;

    final previewBytes = Map<int, Uint8List>.from(state.slotPreviewBytes);
    previewBytes.remove(index);

    state = state.copyWith(
      selectedImages: selectedImages,
      slotPreviewBytes: previewBytes,
      draft: state.draft.copyWith(photos: slots),
    );
  }

  void addDamagePhoto(String path) {
    state = state.copyWith(
      draft: state.draft.copyWith(
        damagePhotos: [...state.draft.damagePhotos, path],
      ),
    );
  }

  void onProvinceChanged(String province) {
    updateDraft(state.draft.copyWith(province: province, clearCity: true));
  }

  void onCityChanged(String city) {
    updateDraft(state.draft.copyWith(city: city));
  }

  void onBrandChanged(CarBrand brand) {
    final ai = Set<String>.from(state.aiFilledFields)
      ..remove('brandId')
      ..remove('modelKey');
    state = state.copyWith(
      aiFilledFields: ai,
      draft: state.draft.copyWith(brandId: brand.id, clearModel: true),
    );
  }

  void onModelChanged(String modelKey) {
    final ai = Set<String>.from(state.aiFilledFields)..remove('modelKey');
    state = state.copyWith(
      aiFilledFields: ai,
      draft: state.draft.copyWith(modelKey: modelKey),
    );
  }

  void onColorChanged(String colorKey) {
    final ai = Set<String>.from(state.aiFilledFields)..remove('colorKey');
    state = state.copyWith(
      aiFilledFields: ai,
      draft: state.draft.copyWith(colorKey: colorKey),
    );
  }

  void applyAiSuggestion(AddCarDraft draft, Set<String> aiFilled) {
    state = state.copyWith(draft: draft, aiFilledFields: aiFilled);
  }

  void onYearChanged(String year) =>
      updateDraft(state.draft.copyWith(year: year));

  void onTrimChanged(String trim) =>
      updateDraft(state.draft.copyWith(trim: trim));

  void onPlateTypeChanged(String plateTypeKey) =>
      updateDraft(state.draft.copyWith(plateTypeKey: plateTypeKey));

  void onPlateCityChanged(String plateCityKey) =>
      updateDraft(state.draft.copyWith(plateCityKey: plateCityKey));

  void onMileageChanged(String mileageValue) =>
      updateDraft(state.draft.copyWith(mileageValue: mileageValue));

  void onMileageUnitChanged(String mileageUnit) =>
      updateDraft(state.draft.copyWith(mileageUnit: mileageUnit));

  void onFuelChanged(String fuelKey) =>
      updateDraft(state.draft.copyWith(fuelKey: fuelKey));

  void onImportCountryChanged(String importCountryKey) =>
      updateDraft(state.draft.copyWith(importCountryKey: importCountryKey));

  void onTransmissionChanged(String transmissionKey) =>
      updateDraft(state.draft.copyWith(transmissionKey: transmissionKey));

  void onCylindersChanged(String cylindersKey) =>
      updateDraft(state.draft.copyWith(cylindersKey: cylindersKey));

  void onEngineSizeChanged(String engineSizeKey) =>
      updateDraft(state.draft.copyWith(engineSizeKey: engineSizeKey));

  void onSeatMaterialChanged(String seatMaterialKey) =>
      updateDraft(state.draft.copyWith(seatMaterialKey: seatMaterialKey));

  void onSeatCountChanged(String seatCountKey) =>
      updateDraft(state.draft.copyWith(seatCountKey: seatCountKey));

  void onConditionChanged(String conditionKey) =>
      updateDraft(state.draft.copyWith(conditionKey: conditionKey));

  void onFeatureToggled(String featureKey) {
    final next = Set<String>.from(state.draft.selectedFeatures);
    if (next.contains(featureKey)) {
      next.remove(featureKey);
    } else {
      next.add(featureKey);
    }
    updateDraft(state.draft.copyWith(selectedFeatures: next));
  }

  void onSelectAllFeatures(Set<String> features) {
    updateDraft(state.draft.copyWith(selectedFeatures: features));
  }

  void onDescriptionChanged(String description) =>
      updateDraft(state.draft.copyWith(description: description));

  void onPriceChanged(String priceValue) =>
      updateDraft(state.draft.copyWith(priceValue: priceValue));

  void onCurrencyChanged(String currencyKey) =>
      updateDraft(state.draft.copyWith(currencyKey: currencyKey));

  void onPackageChanged(String packageKey) =>
      updateDraft(state.draft.copyWith(packageKey: packageKey));

  void onPaymentMethodChanged(String paymentMethodKey) =>
      updateDraft(state.draft.copyWith(paymentMethodKey: paymentMethodKey));

  Future<void> saveDraftManually() async {
    if (state.isPublishing ||
        state.isSavingDraft ||
        state.isAnyPhotoUploading ||
        state.isEditMode) {
      return;
    }

    final sellerId = FirebaseAuth.instance.currentUser?.uid;
    if (sellerId == null) {
      throw CarDatabaseException('Sign in required to save a draft.');
    }

    if (!state.draft.hasDraftContent) {
      throw const AddCarDraftEmptyException();
    }

    setSavingDraft(true);

    try {
      await _persistDraft(sellerId);
      setSavingDraft(false);
    } catch (e) {
      setSavingDraft(false);
      rethrow;
    }
  }

  Future<void> _persistDraft(String sellerId) async {
    final r2 = await readR2StorageServiceForUpload(ref);
    final carDb = ref.read(carDatabaseServiceProvider);

    final uploadResults = await Future.wait([
      uploadCarImagesConcurrent(
        r2,
        state.draft.normalizedPhotos(),
        xFiles: state.selectedImages,
        previewBytesBySlot: state.slotPreviewBytes,
      ),
      state.draft.damagePhotos.isNotEmpty
          ? uploadCarImagesConcurrent(
              r2,
              state.draft.damagePhotos.cast<String?>(),
            )
          : Future<List<String>>.value(const []),
    ]);

    final imageUrls = uploadResults[0];
    final damageUrls = uploadResults[1];

    final carData = state.draft.toFirestoreMap(sellerId: sellerId);
    if (damageUrls.isNotEmpty) {
      carData['damageImageUrls'] = damageUrls;
    }

    final draftId = await carDb.saveCarDraft(
      draftId: state.draftAdId ?? _session.existingAdId,
      sellerId: sellerId,
      carData: carData,
      imageUrls: imageUrls,
      lastStep: state.currentStep,
    );

    state = state.copyWith(draftAdId: draftId);
  }

  Future<void> saveChanges() async {
    setPublishing(true);

    final r2 = await readR2StorageServiceForUpload(ref);
    final carDb = ref.read(carDatabaseServiceProvider);
    final sellerId = FirebaseAuth.instance.currentUser?.uid;

    try {
      final hasNewLocalPhotos = state.draft.newLocalPhotoPaths.isNotEmpty;
      final hasNewDamagePhotos = state.draft.newLocalDamagePhotoPaths.isNotEmpty;

      late final List<String> existingImageUrls;
      late final List<String> damageUrls;

      if (hasNewLocalPhotos && hasNewDamagePhotos) {
        final results = await Future.wait([
          uploadCarImagesConcurrent(
            r2,
            state.draft.normalizedPhotos(),
            xFiles: state.selectedImages,
            previewBytesBySlot: state.slotPreviewBytes,
          ),
          uploadCarImagesConcurrent(
            r2,
            state.draft.damagePhotos.cast<String?>(),
          ),
        ]);
        existingImageUrls = results[0];
        damageUrls = results[1];
      } else if (hasNewLocalPhotos) {
        existingImageUrls = await uploadCarImagesConcurrent(
          r2,
          state.draft.normalizedPhotos(),
          xFiles: state.selectedImages,
          previewBytesBySlot: state.slotPreviewBytes,
        );
        damageUrls = state.draft.existingDamageImageUrls;
      } else if (hasNewDamagePhotos) {
        existingImageUrls = state.draft.existingImageUrls;
        damageUrls = await uploadCarImagesConcurrent(
          r2,
          state.draft.damagePhotos.cast<String?>(),
        );
      } else {
        existingImageUrls = state.draft.existingImageUrls;
        damageUrls = state.draft.existingDamageImageUrls;
      }

      if (existingImageUrls.isEmpty) {
        throw R2StorageException('At least 4 photos are required.');
      }

      final carData = state.draft.toFirestoreMap(sellerId: sellerId);
      if (damageUrls.isNotEmpty) {
        carData['damageImageUrls'] = damageUrls;
      }

      await carDb.updateCarAd(
        adId: state.existingAdId!,
        updatedData: carData,
        existingImageUrls: existingImageUrls,
        newImagesToUpload: const [],
      );

      setPublishing(false);
    } catch (e) {
      setPublishing(false);
      rethrow;
    }
  }

  Future<void> publishListing() async {
    setPublishing(true);

    final r2 = await readR2StorageServiceForUpload(ref);
    final carDb = ref.read(carDatabaseServiceProvider);
    final sellerId = FirebaseAuth.instance.currentUser?.uid;

    try {
      final uploadResults = await Future.wait([
        uploadCarImagesConcurrent(
          r2,
          state.draft.normalizedPhotos(),
          xFiles: state.selectedImages,
          previewBytesBySlot: state.slotPreviewBytes,
        ),
        state.draft.damagePhotos.isNotEmpty
            ? uploadCarImagesConcurrent(
                r2,
                state.draft.damagePhotos.cast<String?>(),
              )
            : Future<List<String>>.value(const []),
      ]);

      final imageUrls = uploadResults[0];
      final damageUrls = uploadResults[1];

      if (imageUrls.isEmpty) {
        throw R2StorageException('At least 4 photos are required.');
      }

      final carData = state.draft.toFirestoreMap(sellerId: sellerId);
      carData['imageUrls'] = imageUrls;
      if (damageUrls.isNotEmpty) {
        carData['damageImageUrls'] = damageUrls;
      }

      if (state.isDraftMode && _session.existingAdId != null) {
        await carDb.publishDraftCarAd(
          draftId: _session.existingAdId!,
          carData: carData,
          imageUrls: imageUrls,
        );
      } else if (state.draftAdId != null) {
        await carDb.publishDraftCarAd(
          draftId: state.draftAdId!,
          carData: carData,
          imageUrls: imageUrls,
        );
      } else {
        await carDb.publishCarAd(carData, imageUrls);
      }

      setPublishing(false);
    } catch (e, stackTrace) {
      webDebugLog('Publish failed: $e\n$stackTrace');
      setPublishing(false);
      rethrow;
    }
  }
}

class AddCarDraftEmptyException implements Exception {
  const AddCarDraftEmptyException();
}
