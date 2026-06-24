import 'package:iq_motors/shared/data/add_car_form_options.dart';
import 'package:iq_motors/shared/data/add_car_option_keys.dart';

/// In-progress listing data collected across the add-car wizard.
class AddCarDraft {
  const AddCarDraft({
    this.province,
    this.city,
    this.photos = const [],
    this.brandId,
    this.modelKey,
    this.colorKey,
    this.year,
    this.trim,
    this.plateTypeKey,
    this.plateCityKey,
    this.mileageValue,
    this.mileageUnit = AddCarOptionKeys.mileageUnitKm,
    this.fuelKey = AddCarFormOptions.defaultFuelKey,
    this.importCountryKey,
    this.transmissionKey,
    this.cylindersKey,
    this.engineSizeKey,
    this.seatMaterialKey,
    this.seatCountKey,
    this.conditionKey,
    this.selectedFeatures = const {},
    this.damagePhotos = const [],
    this.description,
    this.priceValue,
    this.currencyKey = AddCarFormOptions.defaultCurrencyKey,
    this.packageKey,
    this.paymentMethodKey,
  });

  static const int photoSlotCount = 9;
  static const int minPhotoCount = 4;

  final String? province;
  final String? city;
  final List<String?> photos;
  final String? brandId;
  final String? modelKey;
  final String? colorKey;
  final String? year;
  final String? trim;
  final String? plateTypeKey;
  final String? plateCityKey;
  final String? mileageValue;
  final String mileageUnit;
  final String? fuelKey;
  final String? importCountryKey;
  final String? transmissionKey;
  final String? cylindersKey;
  final String? engineSizeKey;
  final String? seatMaterialKey;
  final String? seatCountKey;
  final String? conditionKey;
  final Set<String> selectedFeatures;
  final List<String> damagePhotos;
  final String? description;
  final String? priceValue;
  final String currencyKey;
  final String? packageKey;
  final String? paymentMethodKey;

  bool get isLocationComplete =>
      province != null &&
      province!.isNotEmpty &&
      city != null &&
      city!.isNotEmpty;

  int get filledPhotoCount => photos.where((p) => p != null).length;

  bool get hasMinimumPhotos => filledPhotoCount >= minPhotoCount;

  bool get isBasicInfoComplete =>
      brandId != null &&
      brandId!.isNotEmpty &&
      modelKey != null &&
      modelKey!.isNotEmpty &&
      colorKey != null &&
      colorKey!.isNotEmpty &&
      year != null &&
      year!.isNotEmpty &&
      trim != null &&
      trim!.isNotEmpty;

  bool get isPlateInfoComplete =>
      plateTypeKey != null &&
      plateTypeKey!.isNotEmpty &&
      plateCityKey != null &&
      plateCityKey!.isNotEmpty;

  int? get parsedMileage {
    final raw = mileageValue?.replaceAll(',', '').trim();
    if (raw == null || raw.isEmpty) return null;
    return int.tryParse(raw);
  }

  bool get isMileageFuelComplete =>
      parsedMileage != null &&
      fuelKey != null &&
      fuelKey!.isNotEmpty;

  bool get isTechnicalComplete =>
      importCountryKey != null &&
      importCountryKey!.isNotEmpty &&
      transmissionKey != null &&
      transmissionKey!.isNotEmpty &&
      cylindersKey != null &&
      cylindersKey!.isNotEmpty &&
      engineSizeKey != null &&
      engineSizeKey!.isNotEmpty;

  bool get isInteriorComplete =>
      seatMaterialKey != null &&
      seatMaterialKey!.isNotEmpty &&
      seatCountKey != null &&
      seatCountKey!.isNotEmpty;

  bool get isConditionFeaturesComplete =>
      conditionKey != null && conditionKey!.isNotEmpty;

  int? get parsedPrice {
    final raw = priceValue?.replaceAll(',', '').trim();
    if (raw == null || raw.isEmpty) return null;
    return int.tryParse(raw);
  }

  bool get isPriceDescriptionComplete =>
      parsedPrice != null &&
      parsedPrice! > 0 &&
      currencyKey.isNotEmpty;

  bool get isReviewComplete => isPriceDescriptionComplete;

  bool get isPackageComplete =>
      packageKey != null && packageKey!.isNotEmpty;

  bool get isPaymentComplete =>
      paymentMethodKey != null && paymentMethodKey!.isNotEmpty;

  /// Whether the wizard has enough data worth auto-saving as a draft.
  bool get hasDraftContent =>
      filledPhotoCount > 0 ||
      (province != null && province!.isNotEmpty) ||
      (city != null && city!.isNotEmpty) ||
      (brandId != null && brandId!.isNotEmpty) ||
      (modelKey != null && modelKey!.isNotEmpty) ||
      (priceValue != null && priceValue!.trim().isNotEmpty) ||
      (description != null && description!.trim().isNotEmpty);

  AddCarDraft copyWith({
    String? province,
    String? city,
    bool clearCity = false,
    List<String?>? photos,
    String? brandId,
    String? modelKey,
    bool clearModel = false,
    String? colorKey,
    String? year,
    String? trim,
    String? plateTypeKey,
    String? plateCityKey,
    String? mileageValue,
    String? mileageUnit,
    String? fuelKey,
    String? importCountryKey,
    String? transmissionKey,
    String? cylindersKey,
    String? engineSizeKey,
    String? seatMaterialKey,
    String? seatCountKey,
    String? conditionKey,
    Set<String>? selectedFeatures,
    List<String>? damagePhotos,
    String? description,
    String? priceValue,
    String? currencyKey,
    String? packageKey,
    String? paymentMethodKey,
  }) {
    return AddCarDraft(
      province: province ?? this.province,
      city: clearCity ? null : (city ?? this.city),
      photos: photos ?? this.photos,
      brandId: brandId ?? this.brandId,
      modelKey: clearModel ? null : (modelKey ?? this.modelKey),
      colorKey: colorKey ?? this.colorKey,
      year: year ?? this.year,
      trim: trim ?? this.trim,
      plateTypeKey: plateTypeKey ?? this.plateTypeKey,
      plateCityKey: plateCityKey ?? this.plateCityKey,
      mileageValue: mileageValue ?? this.mileageValue,
      mileageUnit: mileageUnit ?? this.mileageUnit,
      fuelKey: fuelKey ?? this.fuelKey,
      importCountryKey: importCountryKey ?? this.importCountryKey,
      transmissionKey: transmissionKey ?? this.transmissionKey,
      cylindersKey: cylindersKey ?? this.cylindersKey,
      engineSizeKey: engineSizeKey ?? this.engineSizeKey,
      seatMaterialKey: seatMaterialKey ?? this.seatMaterialKey,
      seatCountKey: seatCountKey ?? this.seatCountKey,
      conditionKey: conditionKey ?? this.conditionKey,
      selectedFeatures: selectedFeatures ?? this.selectedFeatures,
      damagePhotos: damagePhotos ?? this.damagePhotos,
      description: description ?? this.description,
      priceValue: priceValue ?? this.priceValue,
      currencyKey: currencyKey ?? this.currencyKey,
      packageKey: packageKey ?? this.packageKey,
      paymentMethodKey: paymentMethodKey ?? this.paymentMethodKey,
    );
  }

  List<String?> normalizedPhotos() {
    if (photos.length >= photoSlotCount) {
      return List<String?>.from(photos.take(photoSlotCount));
    }
    return [
      ...photos,
      ...List<String?>.filled(photoSlotCount - photos.length, null),
    ];
  }

  /// Local file paths for filled photo slots (excludes placeholders).
  List<String> get localPhotoPaths =>
      normalizedPhotos().whereType<String>().toList();

  static bool isRemoteImageUrl(String path) =>
      path.startsWith('http://') || path.startsWith('https://');

  /// Remote URLs already stored for this listing (edit mode).
  List<String> get existingImageUrls =>
      localPhotoPaths.where(isRemoteImageUrl).toList();

  /// Newly picked local files that still need uploading (edit mode).
  List<String> get newLocalPhotoPaths =>
      localPhotoPaths.where((p) => !isRemoteImageUrl(p)).toList();

  List<String> get existingDamageImageUrls =>
      damagePhotos.where(isRemoteImageUrl).toList();

  List<String> get newLocalDamagePhotoPaths =>
      damagePhotos.where((p) => !isRemoteImageUrl(p)).toList();

  /// Reconstructs an existing Firestore car document into wizard state.
  factory AddCarDraft.fromFirestoreMap(Map<String, dynamic> data) {
    final imageUrls = (data['imageUrls'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];
    final damageUrls = (data['damageImageUrls'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];

    final rawFeatures = data['features'];
    final Set<String> selectedFeatures;
    if (rawFeatures is List) {
      selectedFeatures = rawFeatures.map((e) => e.toString()).toSet();
    } else {
      selectedFeatures = {};
    }

    return AddCarDraft(
      province: _stringField(data['province']),
      city: _stringField(data['city']),
      photos: imageUrls.cast<String?>(),
      brandId: _stringField(data['brandId']),
      modelKey: _stringField(data['modelKey']),
      colorKey: _stringField(data['colorKey']),
      year: _stringField(data['year']),
      trim: _stringField(data['trim']),
      plateTypeKey: _stringField(data['plateTypeKey']),
      plateCityKey: _stringField(data['plateCityKey']),
      mileageValue: _numericField(data['mileageValue']),
      mileageUnit:
          _stringField(data['mileageUnit']) ?? AddCarOptionKeys.mileageUnitKm,
      fuelKey: _stringField(data['fuelKey']) ?? AddCarFormOptions.defaultFuelKey,
      importCountryKey: _stringField(data['importCountryKey']),
      transmissionKey: _stringField(data['transmissionKey']),
      cylindersKey: _stringField(data['cylindersKey']),
      engineSizeKey: _stringField(data['engineSizeKey']),
      seatMaterialKey: _stringField(data['seatMaterialKey']),
      seatCountKey: _stringField(data['seatCountKey']),
      conditionKey: _stringField(data['conditionKey']),
      selectedFeatures: selectedFeatures,
      damagePhotos: damageUrls,
      description: _stringField(data['description']),
      priceValue: _numericField(data['priceValue']),
      currencyKey:
          _stringField(data['currencyKey']) ?? AddCarFormOptions.defaultCurrencyKey,
      packageKey: _stringField(data['packageKey']),
      paymentMethodKey: _stringField(data['paymentMethodKey']),
    );
  }

  static String? _stringField(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static String? _numericField(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  /// Firestore-ready map of textual listing fields (images added separately).
  Map<String, dynamic> toFirestoreMap({String? sellerId}) {
    return {
      if (sellerId != null) 'sellerId': sellerId,
      'province': province,
      'city': city,
      'brandId': brandId,
      'modelKey': modelKey,
      'colorKey': colorKey,
      'year': year,
      'trim': trim,
      'plateTypeKey': plateTypeKey,
      'plateCityKey': plateCityKey,
      'mileageValue': parsedMileage,
      'mileageUnit': mileageUnit,
      'fuelKey': fuelKey,
      'importCountryKey': importCountryKey,
      'transmissionKey': transmissionKey,
      'cylindersKey': cylindersKey,
      'engineSizeKey': engineSizeKey,
      'seatMaterialKey': seatMaterialKey,
      'seatCountKey': seatCountKey,
      'conditionKey': conditionKey,
      'features': selectedFeatures.toList(),
      'description': description?.trim().isEmpty ?? true ? null : description!.trim(),
      'priceValue': parsedPrice,
      'currencyKey': currencyKey,
      'packageKey': packageKey,
      'paymentMethodKey': paymentMethodKey,
    };
  }
}
