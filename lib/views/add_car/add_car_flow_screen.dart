import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/l10n_extensions.dart';
import '../../l10n/app_localizations.dart';
import '../../models/account_type.dart';
import '../../models/add_car_draft.dart';
import '../../data/add_car_form_options.dart';
import '../../models/car_brand.dart';
import '../../data/add_car_option_keys.dart';
import '../../providers/admin_settings_provider.dart';
import '../../providers/auth_providers.dart';
import '../../providers/storage_providers.dart';
import '../../services/car_database_service.dart';
import '../../services/car_vision_service.dart';
import '../../services/r2_storage_service.dart';
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
  bool _isProcessingPhoto = false;
  bool _isAnalyzingAi = false;
  final Set<String> _aiFilledFields = {};
  late AddCarDraft _draft;
  late List<XFile?> _selectedImages;

  bool get _isEditMode => widget.existingAdId != null;

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
    if (_isPublishing || _isProcessingPhoto) return;
    if (_currentStep == 0) {
      Navigator.of(context).maybePop();
      return;
    }
    _goToStep(_currentStep - 1);
  }

  void _goNext() {
    if (!_canProceed || _isPublishing || _isProcessingPhoto) return;

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

  Future<List<String>> _uploadLocalPhotoPaths(
    R2StorageService r2,
    List<String> photoPaths,
  ) async {
    if (photoPaths.isEmpty) return const [];

    final slots = _draft.normalizedPhotos();
    final urls = <String>[];

    for (final path in photoPaths) {
      final slotIndex = slots.indexOf(path);
      final xFile = slotIndex >= 0 ? _selectedImages[slotIndex] : null;
      final dotIndex = path.lastIndexOf('.');
      final ext =
          dotIndex > 0 ? path.substring(dotIndex).toLowerCase() : '.jpg';
      final uniqueName = '${DateTime.now().millisecondsSinceEpoch}_${urls.length}$ext';

      urls.add(
        await r2.uploadPickedImage(
          path: path,
          xFile: xFile,
          fileName: uniqueName,
        ),
      );
    }

    return urls;
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
      final photoPaths = _draft.localPhotoPaths;
      if (photoPaths.isEmpty) {
        throw R2StorageException(l10n.addCarMinPhotosRequired);
      }

      final imageUrls = await _uploadLocalPhotoPaths(r2, photoPaths);
      if (imageUrls.isEmpty) {
        throw R2StorageException(l10n.addCarUploadFailed);
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

  int _consecutiveEmptySlotsFrom(int startIndex) {
    final slots = _draft.normalizedPhotos();
    var count = 0;
    for (var i = startIndex; i < AddCarDraft.photoSlotCount; i++) {
      if (slots[i] == null) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  Future<void> _onPhotoSlotTapped(int index) async {
    final slots = _draft.normalizedPhotos();
    final slotHasPhoto = slots[index] != null;
    final emptySlots = slotHasPhoto ? 1 : _consecutiveEmptySlotsFrom(index);

    // pickMultiImage is unreliable on web; always use single pick there.
    var picked = <XFile>[];
    if (!kIsWeb && emptySlots > 1) {
      picked = await _imagePicker.pickMultiImage(
        imageQuality: 85,
        limit: emptySlots,
      );
    }
    if (picked.isEmpty) {
      final single = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        requestFullMetadata: !kIsWeb,
      );
      if (single != null) picked = [single];
    }

    if (picked.isEmpty || !mounted) return;

    setState(() => _isProcessingPhoto = true);

    try {
      for (var i = 0; i < picked.length; i++) {
        final slotIndex = index + i;
        if (slotIndex >= AddCarDraft.photoSlotCount) break;

        await _assignPhotoToSlot(slotIndex, picked[i]);
        if (!mounted) return;
      }
    } on CarVisionException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.userMessage),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFFF3B30),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.addCarPhotoCheckFailed),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFFF3B30),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessingPhoto = false);
      }
    }
  }

  Future<void> _assignPhotoToSlot(int index, XFile picked) async {
    final vision = ref.read(carVisionServiceProvider);
    final existingLocal = _draft.localPhotoPaths;
    final firstImagePath =
        existingLocal.isNotEmpty ? existingLocal.first : null;

    await vision.validatePhotoUpload(
      imagePath: picked.path,
      firstImagePath: index == 0 ? null : firstImagePath,
    );

    if (!mounted) return;
    HapticFeedback.lightImpact();

    final slots = _draft.normalizedPhotos();
    setState(() {
      _selectedImages[index] = picked;
      _draft = _draft.copyWith(
        photos: List<String?>.from(slots)..[index] = picked.path,
      );
    });

    if (index == 0 && !kIsWeb) {
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
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    HapticFeedback.lightImpact();
    setState(() {
      _draft = _draft.copyWith(
        damagePhotos: [..._draft.damagePhotos, picked.path],
      );
    });
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
            isProcessing: _isProcessingPhoto,
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
        canProceed: _canProceed && !_isPublishing && !_isProcessingPhoto,
        onBack: _goBack,
        onNext: _goNext,
        backLabel: l10n.back,
        nextLabel: _nextLabel(l10n, _currentStep),
      ),
    ),
        if (_isPublishing)
          _PublishingOverlay(isEditMode: _isEditMode, l10n: l10n),
        if (_isProcessingPhoto)
          _PhotoProcessingOverlay(l10n: l10n),
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

class _PhotoProcessingOverlay extends StatelessWidget {
  const _PhotoProcessingOverlay({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      child: Container(
        color: Colors.black.withValues(alpha: 0.35),
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
                l10n.addCarPhotoProcessing,
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
  });

  final bool canProceed;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final String backLabel;
  final String nextLabel;

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
      child: Row(
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
