import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iq_motors/features/listings/presentation/providers/add_car_flow_provider.dart';
import 'package:iq_motors/features/listings/presentation/steps/add_car_step_basic_info.dart';
import 'package:iq_motors/features/listings/presentation/steps/add_car_step_condition_features.dart';
import 'package:iq_motors/features/listings/presentation/steps/add_car_step_interior.dart';
import 'package:iq_motors/features/listings/presentation/steps/add_car_step_location.dart';
import 'package:iq_motors/features/listings/presentation/steps/add_car_step_mileage_fuel.dart';
import 'package:iq_motors/features/listings/presentation/steps/add_car_step_photos.dart';
import 'package:iq_motors/features/listings/presentation/steps/add_car_step_plate_info.dart';
import 'package:iq_motors/features/listings/presentation/steps/add_car_step_price_description.dart';
import 'package:iq_motors/features/listings/presentation/steps/add_car_step_review.dart';
import 'package:iq_motors/features/listings/presentation/steps/add_car_step_technical.dart';
import 'package:iq_motors/shared/data/add_car_form_options.dart';

/// Shell fields watched by the wizard chrome (app bar, bottom bar, overlays).
typedef AddCarWizardShellState = ({
  int currentStep,
  bool isPublishing,
  bool isAnalyzingAi,
  bool isSavingDraft,
  bool isAnyPhotoUploading,
  bool canProceed,
  bool isEditMode,
  bool hasDraftContent,
});

AddCarWizardShellState selectAddCarWizardShell(AddCarFlowState state) {
  return (
    currentStep: state.currentStep,
    isPublishing: state.isPublishing,
    isAnalyzingAi: state.isAnalyzingAi,
    isSavingDraft: state.isSavingDraft,
    isAnyPhotoUploading: state.isAnyPhotoUploading,
    canProceed: state.canProceed,
    isEditMode: state.isEditMode,
    hasDraftContent: state.draft.hasDraftContent,
  );
}

/// Keeps off-screen wizard steps alive without rebuilding them on every draft edit.
class AddCarKeepAlivePage extends StatefulWidget {
  const AddCarKeepAlivePage({super.key, required this.child});

  final Widget child;

  @override
  State<AddCarKeepAlivePage> createState() => _AddCarKeepAlivePageState();
}

class _AddCarKeepAlivePageState extends State<AddCarKeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

/// PageView body where each step subscribes only to its own slice of wizard state.
class AddCarWizardPageView extends ConsumerWidget {
  const AddCarWizardPageView({
    super.key,
    required this.session,
    required this.pageController,
    required this.onPhotoSlotTapped,
    required this.onPhotoRemoved,
    required this.onDamagePhotoAdded,
    required this.onEditStep,
  });

  final AddCarFlowSession session;
  final PageController pageController;
  final ValueChanged<int> onPhotoSlotTapped;
  final ValueChanged<int> onPhotoRemoved;
  final VoidCallback onDamagePhotoAdded;
  final ValueChanged<int> onEditStep;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PageView(
      controller: pageController,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        AddCarKeepAlivePage(child: _LocationStepHost(session: session)),
        AddCarKeepAlivePage(
          child: _PhotosStepHost(
            session: session,
            onPhotoSlotTapped: onPhotoSlotTapped,
            onPhotoRemoved: onPhotoRemoved,
          ),
        ),
        AddCarKeepAlivePage(child: _BasicInfoStepHost(session: session)),
        AddCarKeepAlivePage(child: _PlateStepHost(session: session)),
        AddCarKeepAlivePage(child: _MileageFuelStepHost(session: session)),
        AddCarKeepAlivePage(child: _TechnicalStepHost(session: session)),
        AddCarKeepAlivePage(child: _InteriorStepHost(session: session)),
        AddCarKeepAlivePage(
          child: _ConditionStepHost(
            session: session,
            onDamagePhotoAdded: onDamagePhotoAdded,
          ),
        ),
        AddCarKeepAlivePage(child: _PriceStepHost(session: session)),
        AddCarKeepAlivePage(
          child: _ReviewStepHost(
            session: session,
            onEditStep: onEditStep,
          ),
        ),
      ],
    );
  }
}

class _LocationStepHost extends ConsumerWidget {
  const _LocationStepHost({required this.session});

  final AddCarFlowSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = addCarFlowProvider(session);
    final province = ref.watch(provider.select((s) => s.draft.province));
    final city = ref.watch(provider.select((s) => s.draft.city));
    final flow = ref.read(provider.notifier);

    return AddCarStepLocation(
      province: province,
      city: city,
      onProvinceChanged: flow.onProvinceChanged,
      onCityChanged: flow.onCityChanged,
    );
  }
}

class _PhotosStepHost extends ConsumerWidget {
  const _PhotosStepHost({
    required this.session,
    required this.onPhotoSlotTapped,
    required this.onPhotoRemoved,
  });

  final AddCarFlowSession session;
  final ValueChanged<int> onPhotoSlotTapped;
  final ValueChanged<int> onPhotoRemoved;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = addCarFlowProvider(session);
    final photos = ref.watch(
      provider.select((s) => s.draft.normalizedPhotos()),
    );
    final uploadingSlots = ref.watch(
      provider.select((s) => s.uploadingPhotoSlots),
    );
    final previewBytes = ref.watch(
      provider.select((s) => s.slotPreviewBytes),
    );

    return AddCarStepPhotos(
      photos: photos,
      onPhotoSlotTapped: onPhotoSlotTapped,
      onPhotoRemoved: onPhotoRemoved,
      uploadingSlots: uploadingSlots,
      previewBytesBySlot: previewBytes,
    );
  }
}

class _BasicInfoStepHost extends ConsumerWidget {
  const _BasicInfoStepHost({required this.session});

  final AddCarFlowSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = addCarFlowProvider(session);
    final brandId = ref.watch(provider.select((s) => s.draft.brandId));
    final modelKey = ref.watch(provider.select((s) => s.draft.modelKey));
    final colorKey = ref.watch(provider.select((s) => s.draft.colorKey));
    final year = ref.watch(provider.select((s) => s.draft.year));
    final trim = ref.watch(provider.select((s) => s.draft.trim));
    final aiFilledFields = ref.watch(
      provider.select((s) => s.aiFilledFields),
    );
    final flow = ref.read(provider.notifier);

    return AddCarStepBasicInfo(
      brandId: brandId,
      modelKey: modelKey,
      colorKey: colorKey,
      year: year,
      trim: trim,
      aiFilledFields: aiFilledFields,
      onBrandChanged: flow.onBrandChanged,
      onModelChanged: flow.onModelChanged,
      onColorChanged: flow.onColorChanged,
      onYearChanged: flow.onYearChanged,
      onTrimChanged: flow.onTrimChanged,
    );
  }
}

class _PlateStepHost extends ConsumerWidget {
  const _PlateStepHost({required this.session});

  final AddCarFlowSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = addCarFlowProvider(session);
    final plateTypeKey = ref.watch(
      provider.select((s) => s.draft.plateTypeKey),
    );
    final plateCityKey = ref.watch(
      provider.select((s) => s.draft.plateCityKey),
    );
    final flow = ref.read(provider.notifier);

    return AddCarStepPlateInfo(
      plateTypeKey: plateTypeKey,
      plateCityKey: plateCityKey,
      onPlateTypeChanged: flow.onPlateTypeChanged,
      onPlateCityChanged: flow.onPlateCityChanged,
    );
  }
}

class _MileageFuelStepHost extends ConsumerWidget {
  const _MileageFuelStepHost({required this.session});

  final AddCarFlowSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = addCarFlowProvider(session);
    final mileageValue = ref.watch(
      provider.select((s) => s.draft.mileageValue),
    );
    final mileageUnit = ref.watch(
      provider.select((s) => s.draft.mileageUnit),
    );
    final fuelKey = ref.watch(provider.select((s) => s.draft.fuelKey));
    final flow = ref.read(provider.notifier);

    return AddCarStepMileageFuel(
      mileageValue: mileageValue,
      mileageUnit: mileageUnit,
      fuelKey: fuelKey,
      onMileageChanged: flow.onMileageChanged,
      onMileageUnitChanged: flow.onMileageUnitChanged,
      onFuelChanged: flow.onFuelChanged,
    );
  }
}

class _TechnicalStepHost extends ConsumerWidget {
  const _TechnicalStepHost({required this.session});

  final AddCarFlowSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = addCarFlowProvider(session);
    final importCountryKey = ref.watch(
      provider.select((s) => s.draft.importCountryKey),
    );
    final transmissionKey = ref.watch(
      provider.select((s) => s.draft.transmissionKey),
    );
    final cylindersKey = ref.watch(
      provider.select((s) => s.draft.cylindersKey),
    );
    final engineSizeKey = ref.watch(
      provider.select((s) => s.draft.engineSizeKey),
    );
    final flow = ref.read(provider.notifier);

    return AddCarStepTechnical(
      importCountryKey: importCountryKey,
      transmissionKey: transmissionKey,
      cylindersKey: cylindersKey,
      engineSizeKey: engineSizeKey,
      onImportCountryChanged: flow.onImportCountryChanged,
      onTransmissionChanged: flow.onTransmissionChanged,
      onCylindersChanged: flow.onCylindersChanged,
      onEngineSizeChanged: flow.onEngineSizeChanged,
    );
  }
}

class _InteriorStepHost extends ConsumerWidget {
  const _InteriorStepHost({required this.session});

  final AddCarFlowSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = addCarFlowProvider(session);
    final seatMaterialKey = ref.watch(
      provider.select((s) => s.draft.seatMaterialKey),
    );
    final seatCountKey = ref.watch(
      provider.select((s) => s.draft.seatCountKey),
    );
    final flow = ref.read(provider.notifier);

    return AddCarStepInterior(
      seatMaterialKey: seatMaterialKey,
      seatCountKey: seatCountKey,
      onSeatMaterialChanged: flow.onSeatMaterialChanged,
      onSeatCountChanged: flow.onSeatCountChanged,
    );
  }
}

class _ConditionStepHost extends ConsumerWidget {
  const _ConditionStepHost({
    required this.session,
    required this.onDamagePhotoAdded,
  });

  final AddCarFlowSession session;
  final VoidCallback onDamagePhotoAdded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = addCarFlowProvider(session);
    final conditionKey = ref.watch(
      provider.select((s) => s.draft.conditionKey),
    );
    final selectedFeatures = ref.watch(
      provider.select((s) => s.draft.selectedFeatures),
    );
    final damagePhotoCount = ref.watch(
      provider.select((s) => s.draft.damagePhotos.length),
    );
    final flow = ref.read(provider.notifier);

    return AddCarStepConditionFeatures(
      conditionKey: conditionKey,
      selectedFeatures: selectedFeatures,
      damagePhotoCount: damagePhotoCount,
      onConditionChanged: flow.onConditionChanged,
      onFeatureToggled: flow.onFeatureToggled,
      onSelectAllFeatures: (selectAll) => flow.onSelectAllFeatures(
        selectAll ? Set<String>.from(AddCarFormOptions.featureKeys) : {},
      ),
      onDamagePhotoAdded: onDamagePhotoAdded,
    );
  }
}

class _PriceStepHost extends ConsumerWidget {
  const _PriceStepHost({required this.session});

  final AddCarFlowSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = addCarFlowProvider(session);
    final description = ref.watch(
      provider.select((s) => s.draft.description),
    );
    final priceValue = ref.watch(
      provider.select((s) => s.draft.priceValue),
    );
    final currencyKey = ref.watch(
      provider.select((s) => s.draft.currencyKey),
    );
    final flow = ref.read(provider.notifier);

    return AddCarStepPriceDescription(
      description: description,
      priceValue: priceValue,
      currencyKey: currencyKey,
      onDescriptionChanged: flow.onDescriptionChanged,
      onPriceChanged: flow.onPriceChanged,
      onCurrencyChanged: flow.onCurrencyChanged,
    );
  }
}

class _ReviewStepHost extends ConsumerWidget {
  const _ReviewStepHost({
    required this.session,
    required this.onEditStep,
  });

  final AddCarFlowSession session;
  final ValueChanged<int> onEditStep;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = addCarFlowProvider(session);
    final draft = ref.watch(provider.select((s) => s.draft));

    return AddCarStepReview(
      draft: draft,
      onEditStep: onEditStep,
    );
  }
}
