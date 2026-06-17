import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/l10n_extensions.dart';
import '../../core/web_debug_log.dart';
import '../../l10n/app_localizations.dart';
import '../../models/account_type.dart';
import '../../models/add_car_draft.dart';
import '../../data/add_car_form_options.dart';
import '../../models/car_brand.dart';
import '../../data/add_car_option_keys.dart';
import '../../providers/admin_settings_provider.dart';
import '../../providers/auth_providers.dart';
import '../../providers/r2_storage_provider.dart';
import '../../providers/storage_providers.dart';
import '../../services/car_database_service.dart';
import '../../services/car_vision_service.dart';
import '../../services/r2_storage_service.dart';
import 'package:http/http.dart' as http;
import 'add_car_theme.dart';
import 'steps/add_car_step_basic_info.dart';
import 'steps/add_car_step_condition_features.dart';
import 'steps/add_car_step_interior.dart';
import 'steps/add_car_step_location.dart';
import 'steps/add_car_step_mileage_fuel.dart';
import 'steps/add_car_step_packages.dart';
import 'steps/add_car_step_payment.dart';
import 'steps/add_car_step_photos.dart';
import 'steps/add_car_step_plate_info.dart';
import 'steps/add_car_step_price_description.dart';
import 'steps/add_car_step_review.dart';
import 'steps/add_car_step_technical.dart';

/// Multi-step wizard for listing a car for sale.
class AddCarFlowScreen extends ConsumerStatefulWidget {
  const AddCarFlowScreen({
    super.key,
    this.existingAdId,
    this.existingCarData,
  });

  final String? existingAdId;
  final Map<String, dynamic>? existingCarData;

  @override
  ConsumerState<AddCarFlowScreen> createState() => _AddCarFlowScreenState();
}

class _AddCarFlowScreenState extends ConsumerState<AddCarFlowScreen> {
  static const int _stepCount = 12;

  final PageController _pageController = PageController();
  final ImagePicker _imagePicker = ImagePicker();
  int _currentStep = 0;
  bool _isPublishing = false;
  bool _isAnalyzingAi = false;
  final Set<int> _uploadingPhotoSlots = {};
  final Map<int, Uint8List> _slotPreviewBytes = {};
  final Set<String> _aiFilledFields = {};
  late AddCarDraft _draft;
  late List<XFile?> _selectedImages;

  bool get _isEditMode => widget.existingAdId != null;

  bool get _isAnyPhotoUploading => _uploadingPhotoSlots.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _draft = widget.existingCarData != null
        ? AddCarDraft.fromFirestoreMap(widget.existingCarData!)
        : const AddCarDraft();
    _selectedImages = List<XFile?>.filled(AddCarDraft.photoSlotCount, null);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _canProceed {
    switch (_currentStep) {
      case 0:
        return _draft.isLocationComplete;
      case 1:
        return _draft.hasMinimumPhotos;
      case 2:
        return _draft.isBasicInfoComplete;
      case 3:
        return _draft.isPlateInfoComplete;
      case 4:
        return _draft.isMileageFuelComplete;
      case 5:
        return _draft.isTechnicalComplete;
      case 6:
        return _draft.isInteriorComplete;
      case 7:
        return _draft.isConditionFeaturesComplete;
      case 8:
        return _draft.isPriceDescriptionComplete;
      case 9:
        return _draft.isReviewComplete;
      case 10:
        return _draft.isPackageComplete;
      case 11:
        return _draft.isPaymentComplete;
      default:
        return false;
    }
  }

  void _goBack() {
    if (_isPublishing || _isAnyPhotoUploading) return;
    if (_currentStep == 0) {
      Navigator.of(context).maybePop();
      return;
    }
    _goToStep(_currentStep - 1);
  }

  void _goNext() {
    if (!_canProceed || _isPublishing || _isAnyPhotoUploading) return;

    if (_currentStep >= _stepCount - 1) {
      if (_isEditMode) {
        _saveChanges();
      } else {
        _publishListing();
      }
      return;
    }

    _goToStep(_currentStep + 1);
  }

  Future<List<String>> _resolveOrderedImageUrls(
    R2StorageService r2,
    List<String?> slots, {
    List<XFile?>? xFiles,
  }) async {
    final result = <String>[];
    final pendingUploads = <({String path, int slotIndex, int resultIndex})>[];

    for (var slotIndex = 0; slotIndex < slots.length; slotIndex++) {
      final slot = slots[slotIndex];
      if (slot == null) continue;
      if (AddCarDraft.isRemoteImageUrl(slot) && !slot.startsWith('blob:')) {
        result.add(slot);
      } else {
        pendingUploads.add((
          path: slot,
          slotIndex: slotIndex,
          resultIndex: result.length,
        ));
        result.add('');
      }
    }

    if (pendingUploads.isNotEmpty) {
      final uploaded = await Future.wait(
        pendingUploads.asMap().entries.map((entry) {
          final uploadIndex = entry.key;
          final pending = entry.value;
          final dotIndex = pending.path.lastIndexOf('.');
          final ext = dotIndex > 0
              ? pending.path.substring(dotIndex).toLowerCase()
              : '.jpg';
          final uniqueName =
              '${DateTime.now().millisecondsSinceEpoch}_$uploadIndex$ext';
          final xFile = xFiles?[pending.slotIndex];
          return r2.uploadPickedImage(
            path: pending.path,
            xFile: xFile,
            fileName: uniqueName,
          );
        }),
      );
      for (var i = 0; i < uploaded.length; i++) {
        result[pendingUploads[i].resultIndex] = uploaded[i];
      }
    }

    return result.where((url) => url.isNotEmpty).toList();
  }

  Future<void> _saveChanges() async {
    HapticFeedback.mediumImpact();
    setState(() => _isPublishing = true);

    final l10n = context.l10n;
    final r2 = ref.read(r2StorageServiceProvider);
    final carDb = ref.read(carDatabaseServiceProvider);
    final sellerId = FirebaseAuth.instance.currentUser?.uid;

    try {
      final hasNewLocalPhotos = _draft.newLocalPhotoPaths.isNotEmpty;
      final List<String> existingImageUrls;
      final List<File> newImagesToUpload;

      if (hasNewLocalPhotos) {
        existingImageUrls = await _resolveOrderedImageUrls(
          r2,
          _draft.normalizedPhotos(),
          xFiles: _selectedImages,
        );
        newImagesToUpload = const [];
      } else {
        existingImageUrls = _draft.existingImageUrls;
        newImagesToUpload = const [];
      }

      if (existingImageUrls.isEmpty && newImagesToUpload.isEmpty) {
        throw R2StorageException(l10n.addCarMinPhotosRequired);
      }

      List<String> damageUrls = _draft.existingDamageImageUrls;
      if (_draft.newLocalDamagePhotoPaths.isNotEmpty) {
        damageUrls = await _resolveOrderedImageUrls(
          r2,
          _draft.damagePhotos.cast<String?>(),
        );
      }

      final carData = _draft.toFirestoreMap(sellerId: sellerId);
      if (damageUrls.isNotEmpty) {
        carData['damageImageUrls'] = damageUrls;
      }

      await carDb.updateCarAd(
        adId: widget.existingAdId!,
        updatedData: carData,
        existingImageUrls: existingImageUrls,
        newImagesToUpload: newImagesToUpload,
      );

      if (!mounted) return;
      setState(() => _isPublishing = false);

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.addCarSaveSuccess),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF34C759),
        ),
      );
    } on R2StorageException catch (e) {
      _showPublishError(e.message);
    } on CarDatabaseException catch (e) {
      _showPublishError(e.message);
    } catch (e) {
      _showPublishError(l10n.addCarSaveFailed);
    }
  }

  Future<void> _publishListing() async {
    HapticFeedback.mediumImpact();
    setState(() => _isPublishing = true);

    final l10n = context.l10n;
    final r2 = ref.read(r2StorageServiceProvider);
    final carDb = ref.read(carDatabaseServiceProvider);
    final sellerId = FirebaseAuth.instance.currentUser?.uid;

    try {
      final imageUrls = await _resolveOrderedImageUrls(
        r2,
        _draft.normalizedPhotos(),
        xFiles: _selectedImages,
      );
      if (imageUrls.isEmpty) {
        throw R2StorageException(l10n.addCarMinPhotosRequired);
      }

      final damageUrls = _draft.damagePhotos.isNotEmpty
          ? await r2.uploadImagePaths(_draft.damagePhotos)
          : <String>[];

      final carData = _draft.toFirestoreMap(sellerId: sellerId);
      if (damageUrls.isNotEmpty) {
        carData['damageImageUrls'] = damageUrls;
      }

      await carDb.publishCarAd(carData, imageUrls);

      if (!mounted) return;
      setState(() => _isPublishing = false);

      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.addCarPublishSuccess),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF34C759),
        ),
      );
    } on R2StorageException catch (e) {
      _showPublishError(e.message);
    } on CarDatabaseException catch (e) {
      _showPublishError(e.message);
    } catch (e) {
      _showPublishError(l10n.addCarPublishFailed);
    }
  }

  void _showPublishError(String message) {
    if (!mounted) return;
    setState(() => _isPublishing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFFF3B30),
      ),
    );
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _onProvinceChanged(String province) {
    setState(() {
      _draft = _draft.copyWith(province: province, clearCity: true);
    });
  }

  void _onCityChanged(String city) {
    setState(() => _draft = _draft.copyWith(city: city));
  }

  void _showPhotoFlowError(Object error) {
    final message = error.toString();
    webDebugLog('Photo flow error: $message');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFFF3B30),
        duration: const Duration(seconds: 10),
      ),
    );
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Photo error'),
        content: SingleChildScrollView(child: Text(message)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Opens the gallery for a single photo (one slot per tap).
  Future<List<_PickedPhoto>> _pickPhotos() async {
    if (kIsWeb) {
      return _pickPhotosWeb();
    }

    final single = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      requestFullMetadata: true,
    );
    if (single == null) return const [];

    final bytes = await _loadXFileBytes(single);
    return [_PickedPhoto(file: single, bytes: bytes)];
  }

  /// Web: pick image and load bytes in memory (never rely on [File.path]).
  Future<List<_PickedPhoto>> _pickPhotosWeb() async {
    Object? filePickerError;
    try {
      final fromFilePicker = await _pickViaFilePickerWeb();
      if (fromFilePicker != null) return [fromFilePicker];
    } catch (e) {
      filePickerError = e;
      webDebugLog('FilePicker failed: $e');
    }

    webDebugLog('FilePicker empty — trying image_picker…');
    try {
      final fromImagePicker = await _pickViaImagePickerWeb();
      if (fromImagePicker != null) return [fromImagePicker];
    } catch (e) {
      if (filePickerError != null) {
        throw Exception(
          'FilePicker: $filePickerError\nimage_picker: $e',
        );
      }
      rethrow;
    }

    if (filePickerError != null) {
      throw Exception('FilePicker failed: $filePickerError');
    }
    return const [];
  }

  Future<_PickedPhoto?> _pickViaFilePickerWeb() async {
    webDebugLog('Opening FilePicker…');
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      webDebugLog('FilePicker cancelled');
      return null;
    }

    final platformFile = result.files.single;
    var bytes = platformFile.bytes;
    if (bytes == null || bytes.isEmpty) {
      final stream = platformFile.readStream;
      if (stream != null) {
        webDebugLog('Reading FilePicker stream…');
        bytes = await _collectStreamBytes(stream);
      }
    }

    webDebugLog('FilePicker ${bytes?.length ?? 0} bytes (${platformFile.name})');
    if (bytes == null || bytes.isEmpty) {
      throw StateError(
        'FilePicker returned no bytes for ${platformFile.name}',
      );
    }

    final name = platformFile.name.isNotEmpty ? platformFile.name : 'photo.jpg';
    return _PickedPhoto(
      file: XFile.fromData(bytes, name: name),
      bytes: bytes,
    );
  }

  Future<_PickedPhoto?> _pickViaImagePickerWeb() async {
    final single = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (single == null) return null;

    final bytes = await _loadXFileBytes(single);
    if (bytes == null || bytes.isEmpty) {
      throw StateError(
        'image_picker returned no bytes for ${single.name} (path: ${single.path})',
      );
    }

    webDebugLog('image_picker ${bytes.length} bytes (${single.name})');
    return _PickedPhoto(file: single, bytes: bytes);
  }

  Future<Uint8List> _collectStreamBytes(Stream<List<int>> stream) async {
    final builder = BytesBuilder(copy: false);
    await stream.forEach(builder.add);
    return builder.takeBytes();
  }

  void _onPhotoSlotTapped(int index) {
    if (_uploadingPhotoSlots.contains(index) || _isPublishing) return;
    _handlePhotoSlotTap(index);
  }

  /// Pick + upload for all platforms (spinner shown before picker opens).
  Future<void> _handlePhotoSlotTap(int index) async {
    setState(() => _uploadingPhotoSlots.add(index));

    try {
      final picked = await _pickPhotos();
      if (!mounted) return;

      if (picked.isEmpty) {
        setState(() => _uploadingPhotoSlots.remove(index));
        return;
      }

      for (var i = 0; i < picked.length; i++) {
        final slotIndex = index + i;
        if (slotIndex >= AddCarDraft.photoSlotCount) break;

        final photo = picked[i];
        if (photo.bytes == null || photo.bytes!.isEmpty) {
          throw StateError(
            'Could not read image bytes for ${photo.file.name}',
          );
        }

        await _assignPhotoToSlot(
          slotIndex,
          photo.file,
          bytes: photo.bytes,
        );
        if (!mounted) return;
      }
    } catch (e, stackTrace) {
      if (!mounted) return;
      setState(() => _uploadingPhotoSlots.remove(index));
      webDebugLog('Photo slot tap failed: $e');
      webDebugLog('$stackTrace');
      _showPhotoFlowError(e);
    }
  }

  Future<Uint8List?> _loadXFileBytes(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      if (bytes.isNotEmpty) return bytes;
    } catch (e) {
      webDebugLog('readAsBytes failed: $e');
      if (!kIsWeb) rethrow;
    }

    if (kIsWeb && file.path.startsWith('blob:')) {
      try {
        final response = await http.get(Uri.parse(file.path));
        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          return response.bodyBytes;
        }
        throw StateError(
          'blob fetch HTTP ${response.statusCode} for ${file.path}',
        );
      } catch (e) {
        webDebugLog('blob fetch failed: $e');
        rethrow;
      }
    }
    return null;
  }

  Future<Uint8List> _readPickedImageBytes(XFile picked, Uint8List? cached) async {
    if (cached != null && cached.isNotEmpty) return cached;

    final loaded = await _loadXFileBytes(picked);
    if (loaded != null && loaded.isNotEmpty) return loaded;

    throw StateError('Could not read image bytes');
  }

  static const bool _enableAiAutoFill = false;

  Future<void> _assignPhotoToSlot(
    int index,
    XFile picked, {
    Uint8List? bytes,
  }) async {
    final pickedName = picked.name;
    final dotIndex = pickedName.lastIndexOf('.');
    final ext =
        dotIndex > 0 ? pickedName.substring(dotIndex).toLowerCase() : '.jpg';
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_$index$ext';

    final imageBytes = await _readPickedImageBytes(picked, bytes);
    if (imageBytes.isEmpty) {
      throw StateError('Image bytes are empty');
    }
    webDebugLog('Uploading ${imageBytes.length} bytes as $fileName');
    final uploadService = ref.read(cloudflareUploadServiceProvider);
    final uploadedUrl = await uploadService.uploadImageToCloudflare(
      imageBytes,
      fileName,
    );
    webDebugLog('Upload OK: $uploadedUrl');

    // NOTE: re-enable CarVision ML Kit validation after upload issues are resolved.
    // if (!kIsWeb) {
    //   final vision = ref.read(carVisionServiceProvider);
    //   ...
    //   await vision.validatePhotoUpload(...);
    // }

    if (!mounted) return;
    HapticFeedback.lightImpact();

    final slots = _draft.normalizedPhotos();
    setState(() {
      _uploadingPhotoSlots.remove(index);
      _selectedImages[index] = null;
      _slotPreviewBytes[index] = imageBytes;
      _draft = _draft.copyWith(
        photos: List<String?>.from(slots)..[index] = uploadedUrl,
      );
    });

    if (_enableAiAutoFill && index == 0 && !kIsWeb) {
      _runAiAutoFill(File(picked.path));
    }
  }

  Future<void> _runAiAutoFill(File imageFile) async {
    if (!mounted) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    setState(() => _isAnalyzingAi = true);

    AccountType accountType = AccountType.individual;
    try {
      final profile = await ref.read(authServiceProvider).fetchProfile(userId);
      accountType = profile?.accountType ?? AccountType.individual;
    } catch (_) {
      // Default to individual quota if profile lookup fails.
    }

    final vision = ref.read(carVisionServiceProvider);
    final outcome = await vision.autoFillAfterValidation(
      imageFile: imageFile,
      userId: userId,
      accountType: accountType,
    );

    if (!mounted) return;
    setState(() => _isAnalyzingAi = false);

    if (outcome.status == CarVisionAutoFillStatus.quotaExceeded ||
        outcome.status == CarVisionAutoFillStatus.unavailable ||
        outcome.status == CarVisionAutoFillStatus.noResults) {
      return;
    }

    final suggestion = outcome.suggestion;
    if (suggestion == null || !suggestion.hasAny) return;

    setState(() => _draft = _applyAiSuggestion(_draft, suggestion));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(CarVisionMessages.aiAutoFillSuccess),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF34C759),
      ),
    );
  }

  AddCarDraft _applyAiSuggestion(
    AddCarDraft draft,
    CarVisionFormSuggestion suggestion,
  ) {
    var next = draft;

    if (suggestion.brandId != null &&
        (draft.brandId == null || draft.brandId!.isEmpty)) {
      next = next.copyWith(brandId: suggestion.brandId, clearModel: true);
      _aiFilledFields.add('brandId');
    }

    if (suggestion.modelKey != null &&
        next.brandId != null &&
        (draft.modelKey == null || draft.modelKey!.isEmpty)) {
      next = next.copyWith(modelKey: suggestion.modelKey);
      _aiFilledFields.add('modelKey');
    }

    if (suggestion.colorKey != null &&
        (draft.colorKey == null || draft.colorKey!.isEmpty)) {
      next = next.copyWith(colorKey: suggestion.colorKey);
      _aiFilledFields.add('colorKey');
    }

    return next;
  }

  void _onBrandChanged(CarBrand brand) {
    setState(() {
      _aiFilledFields.remove('brandId');
      _aiFilledFields.remove('modelKey');
      _draft = _draft.copyWith(brandId: brand.id, clearModel: true);
    });
  }

  void _onModelChanged(String modelKey) {
    setState(() {
      _aiFilledFields.remove('modelKey');
      _draft = _draft.copyWith(modelKey: modelKey);
    });
  }

  void _onColorChanged(String colorKey) {
    setState(() {
      _aiFilledFields.remove('colorKey');
      _draft = _draft.copyWith(colorKey: colorKey);
    });
  }

  void _onYearChanged(String year) {
    setState(() => _draft = _draft.copyWith(year: year));
  }

  void _onTrimChanged(String trim) {
    setState(() => _draft = _draft.copyWith(trim: trim));
  }

  void _onPlateTypeChanged(String plateTypeKey) {
    setState(() => _draft = _draft.copyWith(plateTypeKey: plateTypeKey));
  }

  void _onPlateCityChanged(String plateCityKey) {
    setState(() => _draft = _draft.copyWith(plateCityKey: plateCityKey));
  }

  void _onMileageChanged(String mileageValue) {
    setState(() => _draft = _draft.copyWith(mileageValue: mileageValue));
  }

  void _onMileageUnitChanged(String mileageUnit) {
    setState(() => _draft = _draft.copyWith(mileageUnit: mileageUnit));
  }

  void _onFuelChanged(String fuelKey) {
    setState(() => _draft = _draft.copyWith(fuelKey: fuelKey));
  }

  void _onImportCountryChanged(String importCountryKey) {
    setState(() => _draft = _draft.copyWith(importCountryKey: importCountryKey));
  }

  void _onTransmissionChanged(String transmissionKey) {
    setState(() => _draft = _draft.copyWith(transmissionKey: transmissionKey));
  }

  void _onCylindersChanged(String cylindersKey) {
    setState(() => _draft = _draft.copyWith(cylindersKey: cylindersKey));
  }

  void _onEngineSizeChanged(String engineSizeKey) {
    setState(() => _draft = _draft.copyWith(engineSizeKey: engineSizeKey));
  }

  void _onSeatMaterialChanged(String seatMaterialKey) {
    setState(() => _draft = _draft.copyWith(seatMaterialKey: seatMaterialKey));
  }

  void _onSeatCountChanged(String seatCountKey) {
    setState(() => _draft = _draft.copyWith(seatCountKey: seatCountKey));
  }

  void _onConditionChanged(String conditionKey) {
    setState(() => _draft = _draft.copyWith(conditionKey: conditionKey));
  }

  void _onFeatureToggled(String featureKey) {
    final next = Set<String>.from(_draft.selectedFeatures);
    if (next.contains(featureKey)) {
      next.remove(featureKey);
    } else {
      next.add(featureKey);
    }
    setState(() => _draft = _draft.copyWith(selectedFeatures: next));
  }

  void _onSelectAllFeatures(bool selectAll) {
    setState(() {
      _draft = _draft.copyWith(
        selectedFeatures: selectAll
            ? Set<String>.from(AddCarFormOptions.featureKeys)
            : {},
      );
    });
  }

  Future<void> _onDamagePhotoAdded() async {
    if (_isAnyPhotoUploading || _isPublishing) return;

    try {
      final picked = await _pickPhotos();
      if (picked.isEmpty || !mounted) return;

      HapticFeedback.lightImpact();
      setState(() {
        _draft = _draft.copyWith(
          damagePhotos: [..._draft.damagePhotos, picked.first.file.path],
        );
      });
    } catch (e, stackTrace) {
      if (!mounted) return;
      webDebugLog('Damage photo pick failed: $e');
      webDebugLog('$stackTrace');
      _showPhotoFlowError(e);
    }
  }

  void _onDescriptionChanged(String description) {
    setState(() => _draft = _draft.copyWith(description: description));
  }

  void _onPriceChanged(String priceValue) {
    setState(() => _draft = _draft.copyWith(priceValue: priceValue));
  }

  void _onCurrencyChanged(String currencyKey) {
    setState(() => _draft = _draft.copyWith(currencyKey: currencyKey));
  }

  void _onPackageChanged(String packageKey) {
    setState(() => _draft = _draft.copyWith(packageKey: packageKey));
  }

  void _onPaymentMethodChanged(String paymentMethodKey) {
    setState(() => _draft = _draft.copyWith(paymentMethodKey: paymentMethodKey));
  }

  String _nextLabel(AppLocalizations l10n, int step) {
    if (step >= _stepCount - 1) {
      return _isEditMode ? l10n.addCarSave : l10n.addCarPublish;
    }
    return l10n.next;
  }

  String _stepTitle(AppLocalizations l10n, int step) {
    return switch (step) {
      0 => l10n.addCarStepLocationTitle,
      1 => l10n.addCarStepPhotosTitle,
      2 => l10n.addCarStepInfoTitle,
      3 => l10n.addCarStepPlateTitle,
      4 => l10n.addCarStepDetailsTitle,
      5 => l10n.addCarStepTechnicalTitle,
      6 => l10n.addCarStepInteriorTitle,
      7 => l10n.addCarStepConditionTitle,
      8 => l10n.addCarStepPriceTitle,
      9 => l10n.addCarStepReviewTitle,
      10 => l10n.addCarStepListingTitle,
      11 => l10n.addCarStepPaymentTitle,
      _ => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final progress = (_currentStep + 1) / _stepCount;
    final config = ref.watch(systemConfigProvider).value;

    return Stack(
      children: [
        Scaffold(
      backgroundColor: AddCarTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AddCarTheme.scaffoldBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AddCarTheme.textPrimary,
          onPressed: _goBack,
        ),
        title: Column(
          children: [
            Text(
              _stepTitle(l10n, _currentStep),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AddCarTheme.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 3,
                backgroundColor: AddCarTheme.border,
                color: AddCarTheme.textPrimary,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          if (_isEditMode)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 4),
              child: TextButton(
                onPressed: (_isPublishing || _isAnyPhotoUploading)
                    ? null
                    : _saveChanges,
                child: Text(
                  l10n.addCarSave,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: (_isPublishing || _isAnyPhotoUploading)
                        ? AddCarTheme.textSecondary
                        : AddCarTheme.focusBlue,
                  ),
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(8),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              l10n.addCarStepProgress(_currentStep + 1, _stepCount),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AddCarTheme.textSecondary,
              ),
            ),
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) => setState(() => _currentStep = index),
        children: [
          AddCarStepLocation(
            province: _draft.province,
            city: _draft.city,
            onProvinceChanged: _onProvinceChanged,
            onCityChanged: _onCityChanged,
          ),
          AddCarStepPhotos(
            photos: _draft.normalizedPhotos(),
            onPhotoSlotTapped: _onPhotoSlotTapped,
            uploadingSlots: _uploadingPhotoSlots,
            previewBytesBySlot: _slotPreviewBytes,
          ),
          AddCarStepBasicInfo(
            brandId: _draft.brandId,
            modelKey: _draft.modelKey,
            colorKey: _draft.colorKey,
            year: _draft.year,
            trim: _draft.trim,
            isAnalyzingAi: _isAnalyzingAi,
            aiFilledFields: _aiFilledFields,
            onBrandChanged: _onBrandChanged,
            onModelChanged: _onModelChanged,
            onColorChanged: _onColorChanged,
            onYearChanged: _onYearChanged,
            onTrimChanged: _onTrimChanged,
          ),
          AddCarStepPlateInfo(
            plateTypeKey: _draft.plateTypeKey,
            plateCityKey: _draft.plateCityKey,
            onPlateTypeChanged: _onPlateTypeChanged,
            onPlateCityChanged: _onPlateCityChanged,
          ),
          AddCarStepMileageFuel(
            mileageValue: _draft.mileageValue,
            mileageUnit: _draft.mileageUnit,
            fuelKey: _draft.fuelKey,
            onMileageChanged: _onMileageChanged,
            onMileageUnitChanged: _onMileageUnitChanged,
            onFuelChanged: _onFuelChanged,
          ),
          AddCarStepTechnical(
            importCountryKey: _draft.importCountryKey,
            transmissionKey: _draft.transmissionKey,
            cylindersKey: _draft.cylindersKey,
            engineSizeKey: _draft.engineSizeKey,
            onImportCountryChanged: _onImportCountryChanged,
            onTransmissionChanged: _onTransmissionChanged,
            onCylindersChanged: _onCylindersChanged,
            onEngineSizeChanged: _onEngineSizeChanged,
          ),
          AddCarStepInterior(
            seatMaterialKey: _draft.seatMaterialKey,
            seatCountKey: _draft.seatCountKey,
            onSeatMaterialChanged: _onSeatMaterialChanged,
            onSeatCountChanged: _onSeatCountChanged,
          ),
          AddCarStepConditionFeatures(
            conditionKey: _draft.conditionKey,
            selectedFeatures: _draft.selectedFeatures,
            damagePhotoCount: _draft.damagePhotos.length,
            onConditionChanged: _onConditionChanged,
            onFeatureToggled: _onFeatureToggled,
            onSelectAllFeatures: _onSelectAllFeatures,
            onDamagePhotoAdded: _onDamagePhotoAdded,
          ),
          AddCarStepPriceDescription(
            description: _draft.description,
            priceValue: _draft.priceValue,
            currencyKey: _draft.currencyKey,
            onDescriptionChanged: _onDescriptionChanged,
            onPriceChanged: _onPriceChanged,
            onCurrencyChanged: _onCurrencyChanged,
          ),
          AddCarStepReview(
            draft: _draft,
            onEditStep: _goToStep,
          ),
          AddCarStepPackages(
            selectedPackageKey: _draft.packageKey,
            onPackageChanged: _onPackageChanged,
            boostPriceIqd:
                config?.priceForPackage(AddCarOptionKeys.packageBoost),
            superBoostPriceIqd:
                config?.priceForPackage(AddCarOptionKeys.packageSuperBoost),
          ),
          AddCarStepPayment(
            paymentMethodKey: _draft.paymentMethodKey,
            onPaymentMethodChanged: _onPaymentMethodChanged,
          ),
        ],
      ),
      bottomNavigationBar: _BottomActionBar(
        canProceed: _canProceed && !_isPublishing && !_isAnyPhotoUploading,
        onBack: _goBack,
        onNext: _goNext,
        backLabel: l10n.back,
        nextLabel: _nextLabel(l10n, _currentStep),
        saveLabel: _isEditMode && _currentStep < _stepCount - 1
            ? l10n.addCarSave
            : null,
        onSave: _isEditMode && _currentStep < _stepCount - 1
            ? _saveChanges
            : null,
        canSave: !_isPublishing && !_isAnyPhotoUploading,
      ),
    ),
        if (_isPublishing)
          _PublishingOverlay(isEditMode: _isEditMode, l10n: l10n),
        if (_isAnalyzingAi)
          const _AiAnalyzingChipOverlay(),
      ],
    );
  }
}

class _PublishingOverlay extends StatelessWidget {
  const _PublishingOverlay({
    required this.isEditMode,
    required this.l10n,
  });

  final bool isEditMode;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      child: Container(
        color: Colors.black.withValues(alpha: 0.45),
        alignment: Alignment.center,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          decoration: AddCarTheme.cardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(height: 20),
              Text(
                isEditMode ? l10n.addCarSaving : l10n.addCarPublishing,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AddCarTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickedPhoto {
  const _PickedPhoto({required this.file, this.bytes});

  final XFile file;
  final Uint8List? bytes;
}

class _AiAnalyzingChipOverlay extends StatelessWidget {
  const _AiAnalyzingChipOverlay();

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return IgnorePointer(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.only(bottom: 88 + bottomInset),
          child: const _AiAnalyzingChip(),
        ),
      ),
    );
  }
}

class _AiAnalyzingChip extends StatelessWidget {
  const _AiAnalyzingChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AddCarTheme.cardBg.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AddCarFormOptions.aiAccentText.withValues(alpha: 0.2),
        ),
        boxShadow: AddCarTheme.cardShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AddCarFormOptions.aiAccentText.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'AI analyzing...',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AddCarFormOptions.aiAccentText.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.canProceed,
    required this.onBack,
    required this.onNext,
    required this.backLabel,
    required this.nextLabel,
    this.saveLabel,
    this.onSave,
    this.canSave = true,
  });

  final bool canProceed;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final String backLabel;
  final String nextLabel;
  final String? saveLabel;
  final VoidCallback? onSave;
  final bool canSave;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: AddCarTheme.cardBg.withValues(alpha: 0.96),
        border: Border(
          top: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
        boxShadow: AddCarTheme.cardShadow,
      ),
      padding: EdgeInsetsDirectional.fromSTEB(20, 12, 20, 12 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (saveLabel != null && onSave != null) ...[
            _SaveBarButton(
              label: saveLabel!,
              enabled: canSave,
              onTap: onSave!,
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: _SecondaryBarButton(
                  label: backLabel,
                  onTap: onBack,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PrimaryBarButton(
                  label: nextLabel,
                  enabled: canProceed,
                  onTap: onNext,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SaveBarButton extends StatefulWidget {
  const _SaveBarButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_SaveBarButton> createState() => _SaveBarButtonState();
}

class _SaveBarButtonState extends State<_SaveBarButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel:
          widget.enabled ? () => setState(() => _pressed = false) : null,
      onTap: widget.enabled ? widget.onTap : null,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 120),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: widget.enabled ? 1 : 0.45,
          child: Container(
            width: double.infinity,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AddCarTheme.focusBlue,
              borderRadius: BorderRadius.circular(AddCarTheme.pillRadius),
              boxShadow: [
                BoxShadow(
                  color: AddCarTheme.focusBlue.withValues(alpha: 0.28),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              widget.label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryBarButton extends StatefulWidget {
  const _PrimaryBarButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_PrimaryBarButton> createState() => _PrimaryBarButtonState();
}

class _PrimaryBarButtonState extends State<_PrimaryBarButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: widget.enabled ? () => setState(() => _pressed = false) : null,
      onTap: widget.enabled ? widget.onTap : null,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: widget.enabled ? 1 : 0.4,
          child: Container(
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AddCarTheme.primaryBlack,
              borderRadius: BorderRadius.circular(AddCarTheme.pillRadius),
            ),
            child: Text(
              widget.label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryBarButton extends StatefulWidget {
  const _SecondaryBarButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  State<_SecondaryBarButton> createState() => _SecondaryBarButtonState();
}

class _SecondaryBarButtonState extends State<_SecondaryBarButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AddCarTheme.scaffoldBg,
            borderRadius: BorderRadius.circular(AddCarTheme.inputRadius),
            border: Border.all(color: AddCarTheme.border),
          ),
          child: Text(
            widget.label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AddCarTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
