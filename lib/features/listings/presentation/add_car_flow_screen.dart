import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import 'package:iq_motors/core/localization/l10n_extensions.dart';
import 'package:iq_motors/features/auth/presentation/navigation/post_auth_navigation.dart';
import 'package:iq_motors/core/platform/web_debug_log.dart';
import 'package:iq_motors/l10n/app_localizations.dart';
import 'package:iq_motors/shared/models/account_type.dart';
import 'package:iq_motors/features/listings/domain/models/add_car_draft.dart';
import 'package:iq_motors/shared/data/add_car_form_options.dart';
import 'package:iq_motors/features/auth/presentation/providers/auth_providers.dart';
import 'package:iq_motors/features/listings/presentation/providers/add_car_flow_provider.dart';
import 'package:iq_motors/features/listings/presentation/add_car_theme.dart';
import 'package:iq_motors/features/marketplace/data/services/car_database_service.dart';
import 'package:iq_motors/features/listings/data/services/add_car_image_processor.dart';
import 'package:iq_motors/features/listings/data/services/car_vision_service.dart';
import 'package:iq_motors/features/storage/data/services/cloudflare_upload_service.dart';
import 'package:iq_motors/features/storage/data/services/r2_storage_service.dart';
import 'package:iq_motors/features/storage/presentation/providers/storage_providers.dart';
import 'package:iq_motors/shared/widgets/moderation_error_dialog.dart';
import 'package:http/http.dart' as http;
import 'package:iq_motors/features/listings/presentation/widgets/add_car_wizard_step_hosts.dart';

/// Multi-step wizard for listing a car for sale.
class AddCarFlowScreen extends ConsumerStatefulWidget {
  const AddCarFlowScreen({
    super.key,
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
  ConsumerState<AddCarFlowScreen> createState() => _AddCarFlowScreenState();
}

class _AddCarFlowScreenState extends ConsumerState<AddCarFlowScreen> {
  static const double _pickMaxWidth = 1920;
  static const double _pickMaxHeight = 1920;
  static const int _pickImageQuality = 70;

  final ImagePicker _imagePicker = ImagePicker();
  bool _isExiting = false;

  late final AddCarFlowSession _session = AddCarFlowSession(
    existingAdId: widget.existingAdId,
    existingCarData: widget.existingCarData,
    initialStep: widget.initialStep,
    isDraft: widget.isDraft,
  );

  late final _flowProvider = addCarFlowProvider(_session);

  AddCarFlowNotifier? _flowNotifier;

  AddCarFlowNotifier get _flow => _flowNotifier!;

  @override
  void dispose() {
    _flowNotifier?.releaseMemory();
    super.dispose();
  }

  void _goBack() {
    if (_isExiting) return;

    final flowState = ref.read(_flowProvider);
    if (flowState.isPublishing || flowState.isAnyPhotoUploading || flowState.isAnalyzingAi) {
      return;
    }

    if (flowState.currentStep == 0) {
      _exitWizardToDashboard();
      return;
    }

    _flow.flushPendingTextUpdates();
    _flow.goToStep(flowState.currentStep - 1);
  }

  void _exitWizardToDashboard() {
    if (_isExiting || !mounted) return;
    _isExiting = true;

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    _isExiting = false;
    _exitToDashboard();
  }

  void _exitToDashboard() {
    if (_isExiting || !mounted) return;

    final flowState = ref.read(_flowProvider);
    if (flowState.isPublishing || flowState.isAnyPhotoUploading || flowState.isAnalyzingAi) {
      return;
    }

    _isExiting = true;

    final user = FirebaseAuth.instance.currentUser;
    final profile = ref.read(userProfileProvider).value;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => dashboardForAuthenticatedUser(
          email: user?.email,
          phone: profile?.phone,
          accountType: profile?.accountType,
        ),
      ),
      (route) => route.isFirst,
    );
  }

  Future<void> _saveDraftManually() async {
    final flowState = ref.read(_flowProvider);
    if (flowState.isPublishing ||
        flowState.isSavingDraft ||
        flowState.isAnyPhotoUploading ||
        flowState.isEditMode) {
      return;
    }

    final l10n = context.l10n;
    final sellerId = FirebaseAuth.instance.currentUser?.uid;
    if (sellerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.addCarSaveFailed),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFFF3B30),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();

    try {
      await _flow.saveDraftManually();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.addCarDraftSavedSuccess),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF34C759),
        ),
      );
    } on AddCarDraftEmptyException {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.addCarDraftEmpty),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on R2StorageException catch (e) {
      _showDraftSaveError(e.message);
    } on CarDatabaseException catch (e) {
      _showDraftSaveError(e.message);
    } catch (e) {
      _showDraftSaveError(l10n.addCarSaveFailed);
    }
  }

  void _showDraftSaveError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFFF3B30),
      ),
    );
  }

  void _goNext() {
    _flow.flushPendingTextUpdates();
    final flowState = ref.read(_flowProvider);
    if (!flowState.canProceed ||
        flowState.isPublishing ||
        flowState.isAnyPhotoUploading ||
        flowState.isAnalyzingAi) {
      return;
    }

    if (flowState.currentStep >= AddCarFlowState.stepCount - 1) {
      if (flowState.isEditMode) {
        _saveChanges();
      } else {
        _publishListing();
      }
      return;
    }

    if (flowState.currentStep == 1 && !flowState.aiPhotoAnalysisDone) {
      _runWizardPhotoAnalysisThenAdvance();
      return;
    }

    _flow.goNext();
  }

  Future<void> _runWizardPhotoAnalysisThenAdvance() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      _flow.markAiPhotoAnalysisDone();
      _flow.goNext();
      return;
    }

    final flowState = ref.read(_flowProvider);
    final images = <CarVisionImageInput>[];
    for (var i = 0; i < AddCarDraft.photoSlotCount; i++) {
      final bytes = flowState.slotPreviewBytes[i];
      if (bytes == null || bytes.isEmpty) continue;
      images.add(CarVisionImageInput(bytes: bytes));
    }

    if (images.isEmpty) {
      _flow.markAiPhotoAnalysisDone();
      _flow.goNext();
      return;
    }

    if (!mounted) return;
    _flow.setAnalyzingAi(true);

    try {
      AccountType accountType = AccountType.individual;
      try {
        final profile = await ref.read(authServiceProvider).fetchProfile(userId);
        accountType = profile?.accountType ?? AccountType.individual;
      } catch (_) {
        // Default to individual quota if profile lookup fails.
      }

      final vision = ref.read(carVisionServiceProvider);
      final outcome = await vision.analyzeWizardPhotos(
        images: images,
        userId: userId,
        accountType: accountType,
      );

      if (!mounted) return;

      if (outcome.shouldBlockNavigation) {
        final message = outcome.failure == CarVisionFailure.notAVehicle
            ? CarVisionMessages.notAVehicle
            : CarVisionMessages.inconsistentPhotos;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFFF3B30),
          ),
        );
        return;
      }

      final suggestion = outcome.suggestion;
      if (suggestion != null && suggestion.hasAny) {
        final current = ref.read(_flowProvider);
        final applied = _applyAiSuggestion(
          current.draft,
          suggestion,
          current.aiFilledFields,
        );
        _flow.applyAiSuggestion(applied.draft, applied.aiFilled);
      }

      _flow.markAiPhotoAnalysisDone();
      _flow.goNext();

      if (!mounted) return;
      if (suggestion != null && suggestion.hasAny) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(CarVisionMessages.aiAutoFillSuccess),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFF34C759),
          ),
        );
      } else {
        _showAiGracefulFallback(outcome);
      }
    } catch (e, stackTrace) {
      webDebugLog('Wizard AI analysis failed: $e\n$stackTrace');
      if (!mounted) return;
      _flow.markAiPhotoAnalysisDone();
      _flow.goNext();
      _showAiGracefulFallbackMessage(CarVisionMessages.aiGracefulFallback);
    } finally {
      if (mounted) {
        _flow.setAnalyzingAi(false);
      }
    }
  }

  void _showAiGracefulFallback(CarVisionWizardAnalysis outcome) {
    final message = switch (outcome.status) {
      CarVisionAutoFillStatus.timedOut => CarVisionMessages.aiTimedOut,
      _ => CarVisionMessages.aiGracefulFallback,
    };
    _showAiGracefulFallbackMessage(message);
  }

  void _showAiGracefulFallbackMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _saveChanges() async {
    HapticFeedback.mediumImpact();

    final l10n = context.l10n;

    try {
      await _flow.saveChanges();
      if (!mounted) return;

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.addCarSaveSuccess),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF34C759),
        ),
      );
    } on ImageModerationException catch (e) {
      _showModerationError(e.reason);
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

    final l10n = context.l10n;

    try {
      await _flow.publishListing();
      if (!mounted) return;

      final user = FirebaseAuth.instance.currentUser;
      final profile = ref.read(userProfileProvider).value;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => dashboardForAuthenticatedUser(
            email: user?.email,
            phone: profile?.phone,
            accountType: profile?.accountType,
          ),
        ),
        (route) => route.isFirst,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.addCarPublishSuccess),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF34C759),
        ),
      );
    } on ImageModerationException catch (e) {
      _showModerationError(e.reason);
    } on R2StorageException catch (e) {
      _showPublishError(e.message);
    } on CarDatabaseException catch (e) {
      _showPublishError(e.message);
    } catch (e) {
      _showPublishError(l10n.addCarPublishFailed);
    }
  }

  void _showModerationError(String reason) {
    if (!mounted) return;
    showModerationErrorDialog(context, reason);
  }

  void _showPublishError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFFF3B30),
      ),
    );
  }

  void _showPhotoFlowError(Object error) {
    final message = error.toString();
    webDebugLog('Photo flow error: $message');
    if (error is ImageModerationException) {
      showModerationErrorDialog(context, error.reason);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFFF3B30),
        duration: const Duration(seconds: 10),
      ),
    );
  }

  /// Opens the gallery for a single photo (one slot per tap).
  ///
  /// Returns an empty list when the user cancels (null/empty picker result).
  Future<List<_PickedPhoto>> _pickPhotos() async {
    if (kIsWeb) {
      return _pickPhotosWeb();
    }

    try {
      final single = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: _pickMaxWidth,
        maxHeight: _pickMaxHeight,
        imageQuality: _pickImageQuality,
        requestFullMetadata: false,
      );
      // User dismissed the gallery without choosing a file.
      if (single == null) return const [];

      final bytes = await _loadXFileBytes(single);
      if (bytes == null || bytes.isEmpty) {
        throw StateError('Could not read image bytes for ${single.name}');
      }
      // Re-encode off the UI isolate; keep the original XFile for a stable path.
      final compressed = await prepareAddCarPreviewBytes(bytes);
      return [_PickedPhoto(file: single, bytes: compressed)];
    } catch (e, stackTrace) {
      webDebugLog('pickImage failed: $e');
      webDebugLog('$stackTrace');
      rethrow;
    }
  }

  /// Web: pick image and load bytes in memory (never rely on [File.path]).
  Future<List<_PickedPhoto>> _pickPhotosWeb() async {
    try {
      final fromFilePicker = await _pickViaFilePickerWeb();
      if (fromFilePicker != null) return [fromFilePicker];
      // Cancelled / empty — do not open a second picker without a fresh
      // user gesture (image_picker can hang and leave the slot spinner forever).
      return const [];
    } catch (e) {
      webDebugLog('FilePicker failed: $e — falling back to image_picker');
    }

    try {
      final fromImagePicker = await _pickViaImagePickerWeb();
      if (fromImagePicker != null) return [fromImagePicker];
      return const [];
    } catch (e, stackTrace) {
      webDebugLog('image_picker failed: $e');
      webDebugLog('$stackTrace');
      rethrow;
    }
  }

  Future<_PickedPhoto?> _pickViaFilePickerWeb() async {
    webDebugLog('Opening FilePicker…');
    try {
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

      webDebugLog(
        'FilePicker ${bytes?.length ?? 0} bytes (${platformFile.name})',
      );
      if (bytes == null || bytes.isEmpty) {
        throw StateError(
          'FilePicker returned no bytes for ${platformFile.name}',
        );
      }

      final name =
          platformFile.name.isNotEmpty ? platformFile.name : 'photo.jpg';
      // FilePicker has no imageQuality/maxWidth — compress before holding in memory.
      final compressed = await prepareAddCarPreviewBytes(bytes);
      webDebugLog(
        'FilePicker compressed ${bytes.length} → ${compressed.length} bytes',
      );
      final safeName = name.toLowerCase().endsWith('.jpg') ||
              name.toLowerCase().endsWith('.jpeg')
          ? name
          : '$name.jpg';
      return _PickedPhoto(
        file: XFile.fromData(
          compressed,
          name: safeName,
          mimeType: 'image/jpeg',
        ),
        bytes: compressed,
      );
    } catch (e, stackTrace) {
      webDebugLog('FilePicker pick failed: $e');
      webDebugLog('$stackTrace');
      rethrow;
    }
  }

  Future<_PickedPhoto?> _pickViaImagePickerWeb() async {
    try {
      final single = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: _pickMaxWidth,
        maxHeight: _pickMaxHeight,
        imageQuality: _pickImageQuality,
      );
      if (single == null) return null;

      final bytes = await _loadXFileBytes(single);
      if (bytes == null || bytes.isEmpty) {
        throw StateError(
          'image_picker returned no bytes for ${single.name} (path: ${single.path})',
        );
      }

      // Web pickers may ignore quality params — compress defensively.
      final compressed = await prepareAddCarPreviewBytes(bytes);
      webDebugLog(
        'image_picker ${bytes.length} → ${compressed.length} bytes (${single.name})',
      );
      return _PickedPhoto(
        file: XFile.fromData(
          compressed,
          name: single.name,
          mimeType: 'image/jpeg',
        ),
        bytes: compressed,
      );
    } catch (e, stackTrace) {
      webDebugLog('image_picker web pick failed: $e');
      webDebugLog('$stackTrace');
      rethrow;
    }
  }

  Future<Uint8List> _collectStreamBytes(Stream<List<int>> stream) async {
    final builder = BytesBuilder(copy: false);
    await stream.forEach(builder.add);
    return builder.takeBytes();
  }

  void _onPhotoSlotTapped(int index) {
    final flowState = ref.read(_flowProvider);
    if (flowState.uploadingPhotoSlots.contains(index) ||
        flowState.isPublishing) {
      return;
    }
    _handlePhotoSlotTap(index);
  }

  void _onPhotoRemoved(int index) {
    final flowState = ref.read(_flowProvider);
    if (flowState.uploadingPhotoSlots.contains(index) ||
        flowState.isPublishing) {
      return;
    }

    _flow.removePhotoSlot(index);
    HapticFeedback.lightImpact();
  }

  /// Pick image locally; upload is deferred until publish.
  Future<void> _handlePhotoSlotTap(int index) async {
    final activeSlots = <int>{index};
    _flow.clearPhotoSlotFailed(index);
    // Show the per-slot loading spinner for this box.
    _flow.addUploadingSlot(index);

    try {
      final picked = await _pickPhotos();
      if (!mounted) return;

      // User cancelled the picker (null/empty) — clear loading in [finally]
      // so this box is tappable again.
      if (picked.isEmpty) return;

      // Process slots one at a time so preview setState calls stay cheap.
      for (var i = 0; i < picked.length; i++) {
        final slotIndex = index + i;
        if (slotIndex >= AddCarDraft.photoSlotCount) break;

        if (slotIndex != index) {
          activeSlots.add(slotIndex);
          _flow.clearPhotoSlotFailed(slotIndex);
          _flow.addUploadingSlot(slotIndex);
        }

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
      // Any picker/processing error: stop loading so the user can retry.
      for (final slot in activeSlots) {
        _flow.markPhotoSlotFailed(slot);
      }
      webDebugLog('Photo slot tap failed: $e');
      webDebugLog('$stackTrace');
      if (mounted) {
        _showPhotoFlowError(e);
      }
    } finally {
      // Always clear isUploading for these boxes — cancel, error, or success.
      for (final slot in activeSlots) {
        _flow.removeUploadingSlot(slot);
      }
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

  Future<void> _assignPhotoToSlot(
    int index,
    XFile picked, {
    Uint8List? bytes,
  }) async {
    final imageBytes = await _readPickedImageBytes(picked, bytes);
    if (imageBytes.isEmpty) {
      throw StateError('Image bytes are empty');
    }

    final processedBytes = await prepareAddCarPreviewBytes(imageBytes);
    webDebugLog(
      'Photo ready (${processedBytes.length} bytes) — upload deferred to publish',
    );

    if (!mounted) return;
    HapticFeedback.lightImpact();
    _flow.assignPhotoToSlot(index, picked, processedBytes);
  }

  ({AddCarDraft draft, Set<String> aiFilled}) _applyAiSuggestion(
    AddCarDraft draft,
    CarVisionFormSuggestion suggestion,
    Set<String> aiFilledFields,
  ) {
    var next = draft;
    final aiFilled = Set<String>.from(aiFilledFields);

    if (suggestion.brandId != null &&
        (draft.brandId == null || draft.brandId!.isEmpty)) {
      next = next.copyWith(brandId: suggestion.brandId, clearModel: true);
      aiFilled.add('brandId');
    }

    if (suggestion.modelKey != null &&
        next.brandId != null &&
        (draft.modelKey == null || draft.modelKey!.isEmpty)) {
      next = next.copyWith(modelKey: suggestion.modelKey);
      aiFilled.add('modelKey');
    }

    if (suggestion.colorKey != null &&
        (draft.colorKey == null || draft.colorKey!.isEmpty)) {
      next = next.copyWith(colorKey: suggestion.colorKey);
      aiFilled.add('colorKey');
    }

    return (draft: next, aiFilled: aiFilled);
  }

  Future<void> _onDamagePhotoAdded() async {
    final flowState = ref.read(_flowProvider);
    if (flowState.isAnyPhotoUploading || flowState.isPublishing) return;

    try {
      final picked = await _pickPhotos();
      if (picked.isEmpty || !mounted) return;

      HapticFeedback.lightImpact();
      _flow.addDamagePhoto(picked.first.file.path);
    } catch (e, stackTrace) {
      if (!mounted) return;
      webDebugLog('Damage photo pick failed: $e');
      webDebugLog('$stackTrace');
      _showPhotoFlowError(e);
    }
  }

  String _nextLabel(AppLocalizations l10n, AddCarWizardShellState shell) {
    if (shell.currentStep >= AddCarFlowState.stepCount - 1) {
      return shell.isEditMode ? l10n.addCarSave : l10n.addCarPublish;
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
      _ => '',
    };
  }

  void _goToStep(int step) => _flow.goToStep(step);

  @override
  Widget build(BuildContext context) {
    _flowNotifier = ref.read(_flowProvider.notifier);
    final l10n = context.l10n;
    final shell = ref.watch(
      _flowProvider.select(selectAddCarWizardShell),
    );

    final progress = (shell.currentStep + 1) / AddCarFlowState.stepCount;
    final isEditMode = shell.isEditMode;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _goBack();
      },
      child: Stack(
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
              _stepTitle(l10n, shell.currentStep),
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
          if (isEditMode)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 4),
              child: TextButton(
                onPressed: (shell.isPublishing || shell.isAnyPhotoUploading)
                    ? null
                    : _saveChanges,
                child: Text(
                  l10n.addCarSave,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: (shell.isPublishing || shell.isAnyPhotoUploading)
                        ? AddCarTheme.textSecondary
                        : AddCarTheme.focusBlue,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: TextButton(
              onPressed: (shell.isPublishing || shell.isAnyPhotoUploading)
                  ? null
                  : _exitToDashboard,
              child: Text(
                l10n.addCarExit,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: (shell.isPublishing || shell.isAnyPhotoUploading)
                      ? AddCarTheme.textSecondary
                      : AddCarTheme.textPrimary,
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
              l10n.addCarStepProgress(
                shell.currentStep + 1,
                AddCarFlowState.stepCount,
              ),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AddCarTheme.textSecondary,
              ),
            ),
          ),
        ),
      ),
      body: AddCarWizardPageView(
        session: _session,
        onPhotoSlotTapped: _onPhotoSlotTapped,
        onPhotoRemoved: _onPhotoRemoved,
        onDamagePhotoAdded: _onDamagePhotoAdded,
        onEditStep: _goToStep,
      ),
      bottomNavigationBar: _BottomActionBar(
        canProceed: shell.canProceed &&
            !shell.isPublishing &&
            !shell.isAnyPhotoUploading &&
            !shell.isAnalyzingAi,
        onBack: _goBack,
        onNext: _goNext,
        backLabel: l10n.back,
        nextLabel: _nextLabel(l10n, shell),
        saveLabel: isEditMode
            ? (shell.currentStep < AddCarFlowState.stepCount - 1
                ? l10n.addCarSave
                : null)
            : l10n.addCarSave,
        onSave: isEditMode
            ? (shell.currentStep < AddCarFlowState.stepCount - 1
                ? _saveChanges
                : null)
            : _saveDraftManually,
        canSave: !shell.isPublishing &&
            !shell.isAnyPhotoUploading &&
            !shell.isSavingDraft &&
            (isEditMode || shell.hasDraftContent),
        isSaving: shell.isSavingDraft,
      ),
    ),
        if (shell.isPublishing)
          _PublishingOverlay(
            isEditMode: isEditMode,
            l10n: l10n,
          ),
        if (shell.isAnalyzingAi)
          _AiAnalyzingOverlay(l10n: l10n),
      ],
    ),
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

class _AiAnalyzingOverlay extends StatelessWidget {
  const _AiAnalyzingOverlay({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final locale = l10n.localeName.split('_').first;
    final message = switch (locale) {
      'en' => 'AI analyzing your photos…',
      'ar' => 'الذكاء الاصطناعي يحلل صورك…',
      _ => 'AI خەریکی شیکردنەوەی وێنەکانتە…',
    };
    final subtitle = switch (locale) {
      'en' => 'Verifying photos and detecting brand, model & color',
      'ar' => 'التحقق من الصور واكتشاف الماركة والطراز واللون',
      _ => 'پشتڕاستکردنەوەی وێنەکان و دۆزینەوەی براند، مۆدێل و ڕەنگ',
    };

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
              SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AddCarFormOptions.aiAccentText.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AddCarTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AddCarTheme.textSecondary,
                  height: 1.35,
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
    this.isSaving = false,
  });

  final bool canProceed;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final String backLabel;
  final String nextLabel;
  final String? saveLabel;
  final VoidCallback? onSave;
  final bool canSave;
  final bool isSaving;

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
              enabled: canSave && !isSaving,
              isLoading: isSaving,
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
    this.isLoading = false,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;
  final bool isLoading;

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
            child: widget.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
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
