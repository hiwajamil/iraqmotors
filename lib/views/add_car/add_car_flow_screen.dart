import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/add_car_draft.dart';
import '../../data/add_car_form_options.dart';
import '../../models/car_brand.dart';
import '../../providers/storage_providers.dart';
import '../../services/car_database_service.dart';
import '../../services/r2_storage_service.dart';
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
  const AddCarFlowScreen({super.key});

  @override
  ConsumerState<AddCarFlowScreen> createState() => _AddCarFlowScreenState();
}

class _AddCarFlowScreenState extends ConsumerState<AddCarFlowScreen> {
  static const Color _background = Color(0xFFF5F5F7);
  static const Color _textPrimary = Color(0xFF1D1D1F);
  static const Color _textSecondary = Color(0xFF86868B);

  static const int _stepCount = 12;

  final PageController _pageController = PageController();
  final ImagePicker _imagePicker = ImagePicker();
  int _currentStep = 0;
  bool _isPublishing = false;
  AddCarDraft _draft = const AddCarDraft();

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
    if (_isPublishing) return;
    if (_currentStep == 0) {
      Navigator.of(context).maybePop();
      return;
    }
    _goToStep(_currentStep - 1);
  }

  void _goNext() {
    if (!_canProceed || _isPublishing) return;

    if (_currentStep >= _stepCount - 1) {
      _publishListing();
      return;
    }

    _goToStep(_currentStep + 1);
  }

  Future<void> _publishListing() async {
    HapticFeedback.mediumImpact();
    setState(() => _isPublishing = true);

    final r2 = ref.read(r2StorageServiceProvider);
    final carDb = ref.read(carDatabaseServiceProvider);
    final sellerId = FirebaseAuth.instance.currentUser?.uid;

    try {
      final photoPaths = _draft.localPhotoPaths;
      if (photoPaths.isEmpty) {
        throw R2StorageException('تکایە لانیکەم ٤ وێنە هەڵبژێرە.');
      }

      final imageUrls = await r2.uploadImagePaths(photoPaths);
      if (imageUrls.isEmpty) {
        throw R2StorageException('بارکردنی وێنەکان سەرکەوتوو نەبوو.');
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
        const SnackBar(
          content: Text('ڕاگەیاندنەکەت بە سەرکەوتوویی بڵاوکرایەوە'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF34C759),
        ),
      );
    } on R2StorageException catch (e) {
      _showPublishError(e.message);
    } on CarDatabaseException catch (e) {
      _showPublishError(e.message);
    } catch (e) {
      _showPublishError('بڵاوکردنەوە سەرکەوتوو نەبوو. دووبارە هەوڵ بدەرەوە.');
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

  Future<void> _onPhotoAdded(int index) async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    HapticFeedback.lightImpact();
    final slots = _draft.normalizedPhotos();
    setState(() {
      slots[index] = picked.path;
      _draft = _draft.copyWith(photos: slots);
    });
  }

  void _onBrandChanged(CarBrand brand) {
    setState(() {
      _draft = _draft.copyWith(brandId: brand.id, clearModel: true);
    });
  }

  void _onModelChanged(String modelKey) {
    setState(() => _draft = _draft.copyWith(modelKey: modelKey));
  }

  void _onColorChanged(String colorKey) {
    setState(() => _draft = _draft.copyWith(colorKey: colorKey));
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

  String _nextLabel(int step) {
    return switch (step) {
      11 => 'بڵاوکردنەوە',
      _ when step >= _stepCount - 1 => 'بڵاوکردنەوە',
      _ => 'دواتر',
    };
  }

  String _stepTitle(int step) {
    return switch (step) {
      0 => 'شوێن',
      1 => 'وێنەکان',
      2 => 'زانیاری',
      3 => 'تابلۆ',
      4 => 'وردەکاری',
      5 => 'تەکنیکی',
      6 => 'ناوەوە',
      7 => 'دۆخ',
      8 => 'نرخ',
      9 => 'پێداچوونەوە',
      10 => 'بڵاوکردنەوە',
      11 => 'پارەدان',
      _ => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_currentStep + 1) / _stepCount;

    return Stack(
      children: [
        Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: _textPrimary,
          onPressed: _goBack,
        ),
        title: Column(
          children: [
            Text(
              _stepTitle(_currentStep),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 3,
                backgroundColor: const Color(0xFFE5E5EA),
                color: _textPrimary,
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
              'هەنگاو ${_currentStep + 1} لە $_stepCount',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _textSecondary,
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
            onPhotoAdded: _onPhotoAdded,
          ),
          AddCarStepBasicInfo(
            brandId: _draft.brandId,
            modelKey: _draft.modelKey,
            colorKey: _draft.colorKey,
            year: _draft.year,
            trim: _draft.trim,
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
          ),
          AddCarStepPayment(
            paymentMethodKey: _draft.paymentMethodKey,
            onPaymentMethodChanged: _onPaymentMethodChanged,
          ),
        ],
      ),
      bottomNavigationBar: _BottomActionBar(
        canProceed: _canProceed && !_isPublishing,
        onBack: _goBack,
        onNext: _goNext,
        nextLabel: _nextLabel(_currentStep),
      ),
    ),
        if (_isPublishing) const _PublishingOverlay(),
      ],
    );
  }
}

class _PublishingOverlay extends StatelessWidget {
  const _PublishingOverlay();

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      child: Container(
        color: Colors.black.withValues(alpha: 0.45),
        alignment: Alignment.center,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              SizedBox(height: 20),
              Text(
                'خەریکی بڵاوکردنەوە...',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D1D1F),
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
    required this.nextLabel,
  });

  final bool canProceed;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final String nextLabel;

  static const Color _textPrimary = Color(0xFF1D1D1F);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        border: Border(
          top: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
      ),
      padding: EdgeInsetsDirectional.fromSTEB(20, 12, 20, 12 + bottomInset),
      child: Row(
        children: [
          Expanded(
            child: _SecondaryBarButton(
              label: 'گەڕانەوە',
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
              color: _BottomActionBar._textPrimary,
              borderRadius: BorderRadius.circular(14),
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
            color: const Color(0xFFF5F5F7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E5EA)),
          ),
          child: Text(
            widget.label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _BottomActionBar._textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
