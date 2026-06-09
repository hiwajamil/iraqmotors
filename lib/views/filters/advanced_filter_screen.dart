import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/filter_l10n.dart';
import '../../core/l10n_extensions.dart';
import '../../data/car_models_by_brand.dart';
import '../../data/dummy_brands.dart';
import '../../l10n/app_localizations.dart';
import '../../models/advanced_filter_state.dart';
import '../../models/car_brand.dart';
import '../../widgets/brand_search_sheet.dart';
import '../../widgets/filter_option_picker_dialog.dart';

/// Full-screen Apple-style advanced filter modal.
class AdvancedFilterScreen extends StatefulWidget {
  const AdvancedFilterScreen({
    super.key,
    required this.initialFilters,
    this.initialBrand,
    this.resultCount = 12928,
  });

  final AdvancedFilterState initialFilters;
  final CarBrand? initialBrand;
  final int resultCount;

  static Future<AdvancedFilterResult?> show(
    BuildContext context, {
    required AdvancedFilterState initialFilters,
    CarBrand? initialBrand,
    int resultCount = 12928,
  }) {
    return Navigator.of(context).push<AdvancedFilterResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AdvancedFilterScreen(
          initialFilters: initialFilters,
          initialBrand: initialBrand,
          resultCount: resultCount,
        ),
      ),
    );
  }

  @override
  State<AdvancedFilterScreen> createState() => _AdvancedFilterScreenState();
}

class _AdvancedFilterScreenState extends State<AdvancedFilterScreen> {
  static const Color _background = Color(0xFFF5F5F7);
  static const Color _textPrimary = Color(0xFF1D1D1F);
  static const Color _textSecondary = Color(0xFF86868B);

  static const List<String> _years = [
    FilterOptionKeys.allYears,
    '2026',
    '2025',
    '2024',
    '2023',
    '2022',
    '2021',
    '2020',
    '2019',
    '2018',
  ];

  static const List<String> _priceKeys = [
    FilterOptionKeys.allPrices,
    FilterOptionKeys.price20k,
    FilterOptionKeys.price50k,
    FilterOptionKeys.price100k,
    FilterOptionKeys.price100kPlus,
  ];

  static const List<String> _mileageKeys = [
    FilterOptionKeys.allMileages,
    FilterOptionKeys.mileage0,
    FilterOptionKeys.mileage10k,
    FilterOptionKeys.mileage50k,
    FilterOptionKeys.mileage100k,
    FilterOptionKeys.mileage100kPlus,
  ];

  static const List<String> _trimKeys = [
    FilterOptionKeys.all,
    FilterOptionKeys.trimBase,
    FilterOptionKeys.trimSport,
    FilterOptionKeys.trimLuxury,
  ];

  static const List<String> _plateTypeKeys = [
    FilterOptionKeys.all,
    FilterOptionKeys.plateTypePrivate,
    FilterOptionKeys.plateTypeTemporary,
    FilterOptionKeys.plateTypeCommercial,
  ];

  static const List<String> _engineSizeKeys = [
    FilterOptionKeys.all,
    FilterOptionKeys.engineSize1_0,
    FilterOptionKeys.engineSize1_5,
    FilterOptionKeys.engineSize2_0,
    FilterOptionKeys.engineSize3_0,
  ];

  static const List<String> _cylinderKeys = [
    FilterOptionKeys.all,
    FilterOptionKeys.cylinders4,
    FilterOptionKeys.cylinders6,
    FilterOptionKeys.cylinders8,
  ];

  static const List<String> _importCountryKeys = [
    FilterOptionKeys.all,
    FilterOptionKeys.importUae,
    FilterOptionKeys.importUsa,
    FilterOptionKeys.importEurope,
    FilterOptionKeys.importGcc,
    FilterOptionKeys.importLocal,
  ];

  static const List<String> _colorKeys = [
    FilterOptionKeys.colorRed,
    FilterOptionKeys.colorBlue,
    FilterOptionKeys.colorGray,
    FilterOptionKeys.colorBlack,
    FilterOptionKeys.colorWhite,
    FilterOptionKeys.colorSilver,
    FilterOptionKeys.colorGreen,
  ];

  static const List<String> _fuelKeys = [
    FilterOptionKeys.enginePetrol,
    FilterOptionKeys.engineHybrid,
    FilterOptionKeys.engineEv,
  ];

  static const List<String> _seatMaterialKeys = [
    FilterOptionKeys.all,
    FilterOptionKeys.seatFabric,
    FilterOptionKeys.seatLeather,
    FilterOptionKeys.seatSemiLeather,
    FilterOptionKeys.seatAlcantaraLeather,
    FilterOptionKeys.seatAlcantara,
  ];

  late AdvancedFilterState _filters;
  CarBrand? _selectedBrand;

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters;
    _selectedBrand = widget.initialBrand;
  }

  String _formatCount(AppLocalizations l10n, int n) {
    if (l10n.localeName.startsWith('en')) return n.toString();
    const eastern = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((d) {
      final i = int.tryParse(d);
      return i == null ? d : eastern[i];
    }).join();
  }

  String _yearLabel(AppLocalizations l10n, String key) =>
      key == FilterOptionKeys.allYears ? l10n.filterAllYears : key;

  String _modelLabel(AppLocalizations l10n, String key, String languageCode) {
    if (key == CarModelsByBrand.allModelsSentinel) return l10n.filterAllModels;
    if (_selectedBrand == null) return key;
    return CarModelsByBrand.labelForModel(_selectedBrand!, key, languageCode) ??
        key;
  }

  void _updateBrand(CarBrand? brand) {
    setState(() {
      _selectedBrand = brand;
      if (brand == null) {
        _filters = _filters.copyWith(clearModel: true, clearTrim: true);
        return;
      }
      final modelKey = _filters.modelKey;
      if (modelKey != null &&
          !CarModelsByBrand.isValidModelSelection(brand, modelKey)) {
        _filters = _filters.copyWith(clearModel: true, clearTrim: true);
      }
    });
  }

  void _resetAll() {
    setState(() {
      _selectedBrand = null;
      _filters = _filters.cleared();
    });
  }

  void _clearFilters() {
    setState(() => _filters = _filters.cleared());
  }

  void _apply() {
    Navigator.of(context).pop(
      AdvancedFilterResult(filters: _filters, brand: _selectedBrand),
    );
  }

  Future<void> _pickBrandFromCatalog() async {
    final brand = await BrandSearchSheet.show(context);
    if (!mounted) return;
    if (brand != null) _updateBrand(brand);
  }

  Future<void> _openPicker({
    required String title,
    required List<String> optionKeys,
    required String Function(String key) resolveLabel,
    required String? valueKey,
    required ValueChanged<String> onSelected,
    bool searchable = false,
    String? searchHint,
  }) {
    if (!mounted) return Future.value();
    final future = searchable
        ? FilterOptionPickerDialog.showSearchable(
            context,
            title: title,
            searchHint: searchHint ?? title,
            optionKeys: optionKeys,
            resolveLabel: resolveLabel,
            valueKey: valueKey,
          )
        : FilterOptionPickerDialog.show(
            context,
            title: title,
            optionKeys: optionKeys,
            resolveLabel: resolveLabel,
            valueKey: valueKey,
          );
    return future.then((picked) {
      if (!mounted) return;
      if (picked != null) onSelected(picked);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final languageCode = Localizations.localeOf(context).languageCode;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final modelOptionKeys =
        CarModelsByBrand.modelOptionKeysForBrand(_selectedBrand);
    final modelPickerEnabled = _selectedBrand != null &&
        CarModelsByBrand.hasModelsForBrand(_selectedBrand!);
    final selectedModelKey = _selectedBrand != null && _filters.modelKey != null
        ? CarModelsByBrand.canonicalModelKey(
              _selectedBrand!,
              _filters.modelKey,
            ) ??
            _filters.modelKey
        : _filters.modelKey;

    final plateCityKeys = [
      FilterOptionKeys.all,
      ...LocationKeys.pickerOrder.where((k) => k != LocationKeys.allCities),
    ];

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ScreenHeader(
              title: l10n.filterTitle,
              onBack: () => Navigator.of(context).pop(),
              onReset: _resetAll,
              resetLabel: l10n.filterReset,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsetsDirectional.fromSTEB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _FilterSectionLabel(label: l10n.filterBrands),
                    const SizedBox(height: 12),
                    _BrandSquareRow(
                      selectedBrandId: _selectedBrand?.id,
                      onBrandSelected: (brand) =>
                          _updateBrand(_selectedBrand?.id == brand?.id ? null : brand),
                      onViewAllTap: _pickBrandFromCatalog,
                    ),
                    const SizedBox(height: 20),
                    _DropdownPair(
                      left: _FilterDropdownField(
                        label: l10n.filterModel,
                        selectedLabel: selectedModelKey != null
                            ? _modelLabel(
                                l10n,
                                selectedModelKey,
                                languageCode,
                              )
                            : null,
                        placeholder: l10n.filterModelPlaceholder,
                        enabled: modelPickerEnabled,
                        onTap: () => _openPicker(
                          title: l10n.filterModel,
                          searchHint: l10n.filterSearchModel,
                          searchable: true,
                          optionKeys: modelOptionKeys,
                          resolveLabel: (key) =>
                              _modelLabel(l10n, key, languageCode),
                          valueKey: selectedModelKey,
                          onSelected: (key) {
                            final storedKey =
                                key == CarModelsByBrand.allModelsSentinel
                                    ? null
                                    : (_selectedBrand != null
                                        ? CarModelsByBrand.canonicalModelKey(
                                              _selectedBrand!,
                                              key,
                                            ) ??
                                            key
                                        : key);
                            setState(() {
                              _filters = _filters.copyWith(
                                modelKey: storedKey,
                                clearModel:
                                    key == CarModelsByBrand.allModelsSentinel,
                                clearTrim: true,
                              );
                            });
                          },
                        ),
                      ),
                      right: _FilterDropdownField(
                        label: l10n.filterTrim,
                        selectedLabel: _filters.trimKey != null
                            ? FilterL10n.trimLabel(l10n, _filters.trimKey!)
                            : null,
                        placeholder: l10n.filterTrim,
                        enabled: _filters.modelKey != null,
                        onTap: () => _openPicker(
                          title: l10n.filterTrim,
                          optionKeys: _trimKeys,
                          resolveLabel: (key) => key == FilterOptionKeys.all
                              ? l10n.filterAll
                              : FilterL10n.trimLabel(l10n, key),
                          valueKey: _filters.trimKey,
                          onSelected: (key) => setState(() {
                            _filters = _filters.copyWith(
                              trimKey:
                                  key == FilterOptionKeys.all ? null : key,
                              clearTrim: key == FilterOptionKeys.all,
                            );
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _DropdownPair(
                      left: _FilterDropdownField(
                        label: l10n.filterFromYear,
                        selectedLabel: _filters.fromYear,
                        placeholder: l10n.filterFromYear,
                        onTap: () => _openPicker(
                          title: l10n.filterFromYear,
                          optionKeys: _years,
                          resolveLabel: (key) => _yearLabel(l10n, key),
                          valueKey: _filters.fromYear,
                          onSelected: (key) => setState(() {
                            _filters = _filters.copyWith(
                              fromYear:
                                  key == FilterOptionKeys.allYears ? null : key,
                              clearFromYear: key == FilterOptionKeys.allYears,
                            );
                          }),
                        ),
                      ),
                      right: _FilterDropdownField(
                        label: l10n.filterToYear,
                        selectedLabel: _filters.toYear,
                        placeholder: l10n.filterToYear,
                        onTap: () => _openPicker(
                          title: l10n.filterToYear,
                          optionKeys: _years,
                          resolveLabel: (key) => _yearLabel(l10n, key),
                          valueKey: _filters.toYear,
                          onSelected: (key) => setState(() {
                            _filters = _filters.copyWith(
                              toYear:
                                  key == FilterOptionKeys.allYears ? null : key,
                              clearToYear: key == FilterOptionKeys.allYears,
                            );
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _DropdownPair(
                      left: _FilterDropdownField(
                        label: l10n.filterMinPrice,
                        selectedLabel: _filters.minPriceKey != null
                            ? FilterL10n.priceLabel(l10n, _filters.minPriceKey!)
                            : null,
                        placeholder: l10n.filterMinPrice,
                        onTap: () => _openPicker(
                          title: l10n.filterMinPrice,
                          optionKeys: _priceKeys,
                          resolveLabel: (key) => FilterL10n.priceLabel(l10n, key),
                          valueKey: _filters.minPriceKey,
                          onSelected: (key) => setState(() {
                            _filters = _filters.copyWith(
                              minPriceKey:
                                  key == FilterOptionKeys.allPrices ? null : key,
                              clearMinPrice: key == FilterOptionKeys.allPrices,
                            );
                          }),
                        ),
                      ),
                      right: _FilterDropdownField(
                        label: l10n.filterMaxPrice,
                        selectedLabel: _filters.maxPriceKey != null
                            ? FilterL10n.priceLabel(l10n, _filters.maxPriceKey!)
                            : null,
                        placeholder: l10n.filterMaxPrice,
                        onTap: () => _openPicker(
                          title: l10n.filterMaxPrice,
                          optionKeys: _priceKeys,
                          resolveLabel: (key) => FilterL10n.priceLabel(l10n, key),
                          valueKey: _filters.maxPriceKey,
                          onSelected: (key) => setState(() {
                            _filters = _filters.copyWith(
                              maxPriceKey:
                                  key == FilterOptionKeys.allPrices ? null : key,
                              clearMaxPrice: key == FilterOptionKeys.allPrices,
                            );
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _DropdownPair(
                      left: _FilterDropdownField(
                        label: l10n.filterMinMileage,
                        selectedLabel: _filters.minMileageKey != null
                            ? FilterL10n.mileageLabel(
                                l10n,
                                _filters.minMileageKey!,
                              )
                            : null,
                        placeholder: l10n.filterMinMileage,
                        onTap: () => _openPicker(
                          title: l10n.filterMinMileage,
                          optionKeys: _mileageKeys,
                          resolveLabel: (key) =>
                              FilterL10n.mileageLabel(l10n, key),
                          valueKey: _filters.minMileageKey,
                          onSelected: (key) => setState(() {
                            _filters = _filters.copyWith(
                              minMileageKey: key == FilterOptionKeys.allMileages
                                  ? null
                                  : key,
                              clearMinMileage:
                                  key == FilterOptionKeys.allMileages,
                            );
                          }),
                        ),
                      ),
                      right: _FilterDropdownField(
                        label: l10n.filterMaxMileage,
                        selectedLabel: _filters.maxMileageKey != null
                            ? FilterL10n.mileageLabel(
                                l10n,
                                _filters.maxMileageKey!,
                              )
                            : null,
                        placeholder: l10n.filterMaxMileage,
                        onTap: () => _openPicker(
                          title: l10n.filterMaxMileage,
                          optionKeys: _mileageKeys,
                          resolveLabel: (key) =>
                              FilterL10n.mileageLabel(l10n, key),
                          valueKey: _filters.maxMileageKey,
                          onSelected: (key) => setState(() {
                            _filters = _filters.copyWith(
                              maxMileageKey: key == FilterOptionKeys.allMileages
                                  ? null
                                  : key,
                              clearMaxMileage:
                                  key == FilterOptionKeys.allMileages,
                            );
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _DropdownPair(
                      left: _FilterDropdownField(
                        label: l10n.filterPlateCity,
                        selectedLabel: _filters.plateCityKey != null
                            ? FilterL10n.locationLabel(
                                l10n,
                                _filters.plateCityKey!,
                              )
                            : null,
                        placeholder: l10n.filterPlateCity,
                        onTap: () => _openPicker(
                          title: l10n.filterPlateCity,
                          optionKeys: plateCityKeys,
                          resolveLabel: (key) => key == FilterOptionKeys.all
                              ? l10n.filterAll
                              : FilterL10n.locationLabel(l10n, key),
                          valueKey: _filters.plateCityKey,
                          onSelected: (key) => setState(() {
                            _filters = _filters.copyWith(
                              plateCityKey:
                                  key == FilterOptionKeys.all ? null : key,
                              clearPlateCity: key == FilterOptionKeys.all,
                            );
                          }),
                        ),
                      ),
                      right: _FilterDropdownField(
                        label: l10n.filterPlateType,
                        selectedLabel: _filters.plateTypeKey != null
                            ? FilterL10n.plateTypeLabel(
                                l10n,
                                _filters.plateTypeKey!,
                              )
                            : null,
                        placeholder: l10n.filterPlateType,
                        onTap: () => _openPicker(
                          title: l10n.filterPlateType,
                          optionKeys: _plateTypeKeys,
                          resolveLabel: (key) => key == FilterOptionKeys.all
                              ? l10n.filterAll
                              : FilterL10n.plateTypeLabel(l10n, key),
                          valueKey: _filters.plateTypeKey,
                          onSelected: (key) => setState(() {
                            _filters = _filters.copyWith(
                              plateTypeKey:
                                  key == FilterOptionKeys.all ? null : key,
                              clearPlateType: key == FilterOptionKeys.all,
                            );
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _FilterSectionLabel(label: l10n.filterConditionSection),
                    const SizedBox(height: 12),
                    _FilterChipRow(
                      options: [
                        _ChipOption(FilterOptionKeys.all, l10n.filterAll),
                        _ChipOption(
                          FilterOptionKeys.conditionUsed,
                          l10n.conditionUsed,
                        ),
                        _ChipOption(
                          FilterOptionKeys.conditionNew,
                          l10n.conditionNew,
                        ),
                      ],
                      selectedKey:
                          _filters.conditionKey ?? FilterOptionKeys.all,
                      onSelected: (key) => setState(() {
                        _filters = _filters.copyWith(
                          conditionKey:
                              key == FilterOptionKeys.all ? null : key,
                          clearCondition: key == FilterOptionKeys.all,
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    _DropdownPair(
                      left: _FilterDropdownField(
                        label: l10n.filterEngineSize,
                        selectedLabel: _filters.engineSizeKey != null
                            ? FilterL10n.engineSizeLabel(
                                l10n,
                                _filters.engineSizeKey!,
                              )
                            : null,
                        placeholder: l10n.filterEngineSize,
                        onTap: () => _openPicker(
                          title: l10n.filterEngineSize,
                          optionKeys: _engineSizeKeys,
                          resolveLabel: (key) =>
                              FilterL10n.engineSizeLabel(l10n, key),
                          valueKey: _filters.engineSizeKey,
                          onSelected: (key) => setState(() {
                            _filters = _filters.copyWith(
                              engineSizeKey:
                                  key == FilterOptionKeys.all ? null : key,
                              clearEngineSize: key == FilterOptionKeys.all,
                            );
                          }),
                        ),
                      ),
                      right: _FilterDropdownField(
                        label: l10n.filterCylinders,
                        selectedLabel: _filters.cylindersKey != null
                            ? FilterL10n.cylindersLabel(
                                l10n,
                                _filters.cylindersKey!,
                              )
                            : null,
                        placeholder: l10n.filterCylinders,
                        onTap: () => _openPicker(
                          title: l10n.filterCylinders,
                          optionKeys: _cylinderKeys,
                          resolveLabel: (key) =>
                              FilterL10n.cylindersLabel(l10n, key),
                          valueKey: _filters.cylindersKey,
                          onSelected: (key) => setState(() {
                            _filters = _filters.copyWith(
                              cylindersKey:
                                  key == FilterOptionKeys.all ? null : key,
                              clearCylinders: key == FilterOptionKeys.all,
                            );
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _FilterDropdownField(
                      label: l10n.filterImportCountry,
                      selectedLabel: _filters.importCountryKey != null
                          ? FilterL10n.importCountryLabel(
                              l10n,
                              _filters.importCountryKey!,
                            )
                          : null,
                      placeholder: l10n.filterImportCountry,
                      fullWidth: true,
                      onTap: () => _openPicker(
                        title: l10n.filterImportCountry,
                        optionKeys: _importCountryKeys,
                        resolveLabel: (key) => key == FilterOptionKeys.all
                            ? l10n.filterAll
                            : FilterL10n.importCountryLabel(l10n, key),
                        valueKey: _filters.importCountryKey,
                        onSelected: (key) => setState(() {
                          _filters = _filters.copyWith(
                            importCountryKey:
                                key == FilterOptionKeys.all ? null : key,
                            clearImportCountry: key == FilterOptionKeys.all,
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _FilterSectionLabel(label: l10n.filterColor),
                    const SizedBox(height: 12),
                    _ColorSwatchRow(
                      colorKeys: _colorKeys,
                      selectedKey: _filters.colorKey,
                      onSelected: (key) => setState(() {
                        _filters = _filters.copyWith(
                          colorKey: key,
                          clearColor: key == null,
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    _FilterSectionLabel(label: l10n.filterFuelType),
                    const SizedBox(height: 12),
                    _FuelTypeRow(
                      options: _fuelKeys,
                      selectedKey: _filters.engineKey,
                      resolveLabel: (key) => FilterL10n.engineLabel(l10n, key),
                      resolveIcon: (key) => switch (key) {
                        FilterOptionKeys.engineHybrid => Icons.eco_outlined,
                        FilterOptionKeys.engineEv => Icons.electric_bolt_outlined,
                        _ => Icons.local_gas_station_outlined,
                      },
                      onSelected: (key) => setState(() {
                        _filters = _filters.copyWith(
                          engineKey: _filters.engineKey == key ? null : key,
                          clearEngine: _filters.engineKey == key,
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    _FilterSectionLabel(label: l10n.filterTransmission),
                    const SizedBox(height: 12),
                    _FilterChipRow(
                      options: [
                        _ChipOption(FilterOptionKeys.all, l10n.filterAll),
                        _ChipOption(
                          FilterOptionKeys.transmissionAutomatic,
                          l10n.transmissionAutomatic,
                        ),
                        _ChipOption(
                          FilterOptionKeys.transmissionManual,
                          l10n.filterManual,
                        ),
                      ],
                      selectedKey:
                          _filters.transmissionKey ?? FilterOptionKeys.all,
                      onSelected: (key) => setState(() {
                        _filters = _filters.copyWith(
                          transmissionKey:
                              key == FilterOptionKeys.all ? null : key,
                          clearTransmission: key == FilterOptionKeys.all,
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    _FilterSectionLabel(label: l10n.filterSeatMaterial),
                    const SizedBox(height: 12),
                    _FilterChipWrap(
                      options: _seatMaterialKeys
                          .map(
                            (key) => _ChipOption(
                              key,
                              key == FilterOptionKeys.all
                                  ? l10n.filterAll
                                  : FilterL10n.seatMaterialLabel(l10n, key),
                            ),
                          )
                          .toList(),
                      selectedKey:
                          _filters.seatMaterialKey ?? FilterOptionKeys.all,
                      onSelected: (key) => setState(() {
                        _filters = _filters.copyWith(
                          seatMaterialKey:
                              key == FilterOptionKeys.all ? null : key,
                          clearSeatMaterial: key == FilterOptionKeys.all,
                        );
                      }),
                    ),
                    SizedBox(height: 100 + bottomInset),
                  ],
                ),
              ),
            ),
            _StickyBottomBar(
              bottomInset: bottomInset,
              clearLabel: l10n.clearFilters,
              showLabel: l10n.filterShowResults(
                _formatCount(l10n, widget.resultCount),
              ),
              onClear: _clearFilters,
              onShow: _apply,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScreenHeader extends StatelessWidget {
  const _ScreenHeader({
    required this.title,
    required this.onBack,
    required this.onReset,
    required this.resetLabel,
  });

  final String title;
  final VoidCallback onBack;
  final VoidCallback onReset;
  final String resetLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 8, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onReset,
            icon: const Icon(Icons.restart_alt_rounded),
            color: _AdvancedFilterScreenState._textSecondary,
            tooltip: resetLabel,
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _AdvancedFilterScreenState._textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ),
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 20),
            color: _AdvancedFilterScreenState._textPrimary,
          ),
        ],
      ),
    );
  }
}

class _FilterSectionLabel extends StatelessWidget {
  const _FilterSectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: _AdvancedFilterScreenState._textPrimary,
        letterSpacing: -0.2,
      ),
    );
  }
}

class _BrandSquareRow extends StatelessWidget {
  const _BrandSquareRow({
    required this.selectedBrandId,
    required this.onBrandSelected,
    required this.onViewAllTap,
  });

  final String? selectedBrandId;
  final ValueChanged<CarBrand?> onBrandSelected;
  final VoidCallback onViewAllTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: homeStripBrands.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (index == homeStripBrands.length) {
            return _ViewAllBrandCard(onTap: onViewAllTap);
          }
          final brand = homeStripBrands[index];
          final selected = selectedBrandId == brand.id;
          return _BrandSquareCard(
            brand: brand,
            isSelected: selected,
            onTap: () => onBrandSelected(selected ? null : brand),
          );
        },
      ),
    );
  }
}

class _BrandSquareCard extends StatelessWidget {
  const _BrandSquareCard({
    required this.brand,
    required this.isSelected,
    required this.onTap,
  });

  final CarBrand brand;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? _AdvancedFilterScreenState._textPrimary
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.08 : 0.04),
              blurRadius: isSelected ? 12 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: CachedNetworkImage(
              imageUrl: brand.logoUrl,
              fit: BoxFit.contain,
              errorWidget: (_, __, ___) => Center(
                child: Text(
                  brand.nameEnglish[0],
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _AdvancedFilterScreenState._textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ViewAllBrandCard extends StatelessWidget {
  const _ViewAllBrandCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Icon(
          Icons.apps_rounded,
          color: _AdvancedFilterScreenState._textSecondary,
        ),
      ),
    );
  }
}

class _DropdownPair extends StatelessWidget {
  const _DropdownPair({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }
}

class _FilterDropdownField extends StatefulWidget {
  const _FilterDropdownField({
    required this.label,
    required this.onTap,
    this.selectedLabel,
    required this.placeholder,
    this.enabled = true,
    this.fullWidth = false,
  });

  final String label;
  final String? selectedLabel;
  final String placeholder;
  final VoidCallback onTap;
  final bool enabled;
  final bool fullWidth;

  @override
  State<_FilterDropdownField> createState() => _FilterDropdownFieldState();
}

class _FilterDropdownFieldState extends State<_FilterDropdownField> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.selectedLabel != null;
    final textColor = widget.enabled
        ? (hasValue
            ? _AdvancedFilterScreenState._textPrimary
            : _AdvancedFilterScreenState._textSecondary)
        : _AdvancedFilterScreenState._textSecondary.withValues(alpha: 0.5);

    final field = GestureDetector(
      onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel:
          widget.enabled ? () => setState(() => _pressed = false) : null,
      onTap: widget.enabled ? widget.onTap : null,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 10, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _AdvancedFilterScreenState._textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.selectedLabel ?? widget.placeholder,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            hasValue ? FontWeight.w600 : FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 22,
                    color: textColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.fullWidth) return field;
    return field;
  }
}

class _ChipOption {
  const _ChipOption(this.key, this.label);

  final String key;
  final String label;
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: selected
              ? _AdvancedFilterScreenState._textPrimary
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? _AdvancedFilterScreenState._textPrimary
                : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : _AdvancedFilterScreenState._textPrimary,
          ),
        ),
      ),
    );
  }
}

class _FilterChipRow extends StatelessWidget {
  const _FilterChipRow({
    required this.options,
    required this.selectedKey,
    required this.onSelected,
  });

  final List<_ChipOption> options;
  final String selectedKey;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _FilterChip(
              label: options[i].label,
              selected: selectedKey == options[i].key,
              onTap: () => onSelected(options[i].key),
            ),
          ),
        ],
      ],
    );
  }
}

class _FilterChipWrap extends StatelessWidget {
  const _FilterChipWrap({
    required this.options,
    required this.selectedKey,
    required this.onSelected,
  });

  final List<_ChipOption> options;
  final String selectedKey;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options
          .map(
            (o) => _FilterChip(
              label: o.label,
              selected: selectedKey == o.key,
              onTap: () => onSelected(o.key),
            ),
          )
          .toList(),
    );
  }
}

class _FuelTypeRow extends StatelessWidget {
  const _FuelTypeRow({
    required this.options,
    required this.selectedKey,
    required this.resolveLabel,
    required this.resolveIcon,
    required this.onSelected,
  });

  final List<String> options;
  final String? selectedKey;
  final String Function(String key) resolveLabel;
  final IconData Function(String key) resolveIcon;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: _FuelCard(
              label: resolveLabel(options[i]),
              icon: resolveIcon(options[i]),
              selected: selectedKey == options[i],
              onTap: () => onSelected(options[i]),
            ),
          ),
        ],
      ],
    );
  }
}

class _FuelCard extends StatelessWidget {
  const _FuelCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? _AdvancedFilterScreenState._textPrimary
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? _AdvancedFilterScreenState._textPrimary
                : Colors.grey.shade300,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: selected
                  ? Colors.white
                  : _AdvancedFilterScreenState._textPrimary,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected
                    ? Colors.white
                    : _AdvancedFilterScreenState._textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorSwatchRow extends StatelessWidget {
  const _ColorSwatchRow({
    required this.colorKeys,
    required this.selectedKey,
    required this.onSelected,
  });

  final List<String> colorKeys;
  final String? selectedKey;
  final ValueChanged<String?> onSelected;

  static Color _colorForKey(String key) {
    return switch (key) {
      FilterOptionKeys.colorRed => const Color(0xFFE53935),
      FilterOptionKeys.colorBlue => const Color(0xFF1E88E5),
      FilterOptionKeys.colorGray => const Color(0xFF9E9E9E),
      FilterOptionKeys.colorBlack => const Color(0xFF212121),
      FilterOptionKeys.colorWhite => const Color(0xFFFAFAFA),
      FilterOptionKeys.colorSilver => const Color(0xFFBDBDBD),
      FilterOptionKeys.colorGreen => const Color(0xFF43A047),
      _ => Colors.transparent,
    };
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: colorKeys.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _ColorPickerButton(
              selected: selectedKey == null,
              onTap: () => onSelected(null),
            );
          }
          final key = colorKeys[index - 1];
          return _ColorSwatch(
            color: _colorForKey(key),
            selected: selectedKey == key,
            onTap: () => onSelected(key),
          );
        },
      ),
    );
  }
}

class _ColorPickerButton extends StatelessWidget {
  const _ColorPickerButton({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? _AdvancedFilterScreenState._textPrimary
                : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Icon(
          Icons.palette_outlined,
          size: 22,
          color: _AdvancedFilterScreenState._textSecondary,
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? _AdvancedFilterScreenState._textPrimary
                : Colors.grey.shade300,
            width: selected ? 2.5 : 1,
          ),
        ),
      ),
    );
  }
}

class _StickyBottomBar extends StatelessWidget {
  const _StickyBottomBar({
    required this.bottomInset,
    required this.clearLabel,
    required this.showLabel,
    required this.onClear,
    required this.onShow,
  });

  final double bottomInset;
  final String clearLabel;
  final String showLabel;
  final VoidCallback onClear;
  final VoidCallback onShow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsetsDirectional.fromSTEB(20, 14, 20, 14 + bottomInset),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _PrimaryButton(label: showLabel, onTap: onShow),
          ),
          const SizedBox(width: 16),
          TextButton(
            onPressed: onClear,
            style: TextButton.styleFrom(
              foregroundColor: _AdvancedFilterScreenState._textSecondary,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              clearLabel,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatefulWidget {
  const _PrimaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: _AdvancedFilterScreenState._textPrimary,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

