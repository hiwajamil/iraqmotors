import 'package:flutter/material.dart';

import '../core/filter_l10n.dart';
import '../core/l10n_extensions.dart';
import '../data/car_models_by_brand.dart';
import '../l10n/app_localizations.dart';
import '../models/advanced_filter_state.dart';
import '../models/car_brand.dart';
import 'location_picker_sheet.dart';

/// Location + advanced search title row above the brands strip.
class AdvancedFilterHeader extends StatelessWidget {
  const AdvancedFilterHeader({
    super.key,
    required this.selectedLocationKeys,
    required this.onLocationTap,
    this.onAdvancedSearchTap,
  });

  final Set<String> selectedLocationKeys;
  final VoidCallback onLocationTap;
  final VoidCallback? onAdvancedSearchTap;

  @override
  Widget build(BuildContext context) {
    return _FilterHeader(
      selectedLocationKeys: selectedLocationKeys,
      onLocationTap: onLocationTap,
      onAdvancedSearchTap: onAdvancedSearchTap,
    );
  }
}

/// Apple-style advanced search panel — model, year, price, condition, etc.
class AdvancedFilterWidget extends StatelessWidget {
  const AdvancedFilterWidget({
    super.key,
    this.selectedBrand,
    required this.values,
    required this.onChanged,
    required this.onClear,
    required this.onShowResults,
    required this.resultCount,
    this.onLocationTap,
    this.onAdvancedSearchTap,
    this.showHeader = true,
  });

  final CarBrand? selectedBrand;
  final AdvancedFilterState values;
  final ValueChanged<AdvancedFilterState> onChanged;
  final VoidCallback onClear;
  final VoidCallback onShowResults;
  final int resultCount;
  final VoidCallback? onLocationTap;
  final VoidCallback? onAdvancedSearchTap;
  final bool showHeader;

  static const Color _background = Color(0xFFF5F5F7);
  static const Color _fill = Color(0xFFE8E8ED);
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
  ];

  static const List<String> _mileageKeys = [
    FilterOptionKeys.allMileages,
    FilterOptionKeys.mileage0,
    FilterOptionKeys.mileage10k,
    FilterOptionKeys.mileage50k,
    FilterOptionKeys.mileage100k,
    FilterOptionKeys.mileage100kPlus,
  ];

  static const List<String> _priceKeys = [
    FilterOptionKeys.allPrices,
    FilterOptionKeys.price20k,
    FilterOptionKeys.price50k,
    FilterOptionKeys.price100k,
    FilterOptionKeys.price100kPlus,
  ];

  static const List<String> _conditionKeys = [
    FilterOptionKeys.conditionNew,
    FilterOptionKeys.conditionUsed,
  ];

  static const List<String> _engineKeys = [
    FilterOptionKeys.enginePetrol,
    FilterOptionKeys.engineEv,
    FilterOptionKeys.engineHybrid,
  ];

  static String _formatCount(AppLocalizations l10n, int n) {
    if (l10n.localeName.startsWith('en')) {
      return n.toString();
    }
    const eastern = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((d) {
      final i = int.tryParse(d);
      return i == null ? d : eastern[i];
    }).join();
  }

  String _modelLabel(AppLocalizations l10n, String key, String languageCode) {
    if (key == CarModelsByBrand.allModelsSentinel) {
      return l10n.filterAllModels;
    }
    if (selectedBrand == null) return key;
    return CarModelsByBrand.labelForModel(selectedBrand!, key, languageCode) ??
        key;
  }

  String _yearLabel(AppLocalizations l10n, String key) =>
      key == FilterOptionKeys.allYears ? l10n.filterAllYears : key;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final languageCode = Localizations.localeOf(context).languageCode;
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 640 ? 3 : 2;
    final modelOptionKeys =
        CarModelsByBrand.modelOptionKeysForBrand(selectedBrand);
    final modelPickerEnabled = selectedBrand != null &&
        CarModelsByBrand.hasModelsForBrand(selectedBrand!);
    final selectedModelKey = selectedBrand != null && values.modelKey != null
        ? CarModelsByBrand.canonicalModelKey(
              selectedBrand!,
              values.modelKey,
            ) ??
            values.modelKey
        : values.modelKey;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showHeader) ...[
            _FilterHeader(
              selectedLocationKeys: values.selectedLocationKeys,
              onLocationTap: onLocationTap ?? () => _pickLocation(context),
              onAdvancedSearchTap: onAdvancedSearchTap,
            ),
            const SizedBox(height: 20),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth =
                  (constraints.maxWidth - (12 * (columns - 1))) / columns;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _FilterDropdown(
                    width: itemWidth,
                    label: l10n.filterModel,
                    valueKey: selectedModelKey,
                    placeholder: l10n.filterModel,
                    enabled: modelPickerEnabled,
                    optionKeys: modelOptionKeys,
                    resolveLabel: (key) =>
                        _modelLabel(l10n, key, languageCode),
                    onSelected: (key) {
                      final storedKey = key == CarModelsByBrand.allModelsSentinel
                          ? null
                          : (selectedBrand != null
                              ? CarModelsByBrand.canonicalModelKey(
                                    selectedBrand!,
                                    key,
                                  ) ??
                                  key
                              : key);
                      onChanged(
                        values.copyWith(
                          modelKey: storedKey,
                          clearModel: key == CarModelsByBrand.allModelsSentinel,
                        ),
                      );
                    },
                  ),
                  _FilterDropdown(
                    width: itemWidth,
                    label: l10n.filterYear,
                    valueKey: values.year,
                    placeholder: l10n.filterYear,
                    optionKeys: _years,
                    resolveLabel: (key) => _yearLabel(l10n, key),
                    onSelected: (key) => onChanged(
                      values.copyWith(
                        year: key == _years.first ? null : key,
                        clearYear: key == _years.first,
                      ),
                    ),
                  ),
                  _FilterDropdown(
                    width: itemWidth,
                    label: l10n.filterMileage,
                    valueKey: values.mileageKey,
                    placeholder: l10n.filterMileage,
                    optionKeys: _mileageKeys,
                    resolveLabel: (key) => FilterL10n.mileageLabel(l10n, key),
                    onSelected: (key) => onChanged(
                      values.copyWith(
                        mileageKey: key == _mileageKeys.first ? null : key,
                        clearMileage: key == _mileageKeys.first,
                      ),
                    ),
                  ),
                  _FilterDropdown(
                    width: itemWidth,
                    label: l10n.filterPrice,
                    valueKey: values.priceKey,
                    placeholder: l10n.filterPrice,
                    optionKeys: _priceKeys,
                    resolveLabel: (key) => FilterL10n.priceLabel(l10n, key),
                    onSelected: (key) => onChanged(
                      values.copyWith(
                        priceKey: key == _priceKeys.first ? null : key,
                        clearPrice: key == _priceKeys.first,
                      ),
                    ),
                  ),
                  _FilterDropdown(
                    width: itemWidth,
                    label: l10n.filterCondition,
                    valueKey: values.conditionKey,
                    placeholder: l10n.filterCondition,
                    optionKeys: _conditionKeys,
                    resolveLabel: (key) => FilterL10n.conditionLabel(l10n, key),
                    onSelected: (key) =>
                        onChanged(values.copyWith(conditionKey: key)),
                  ),
                  _FilterDropdown(
                    width: itemWidth,
                    label: l10n.filterEngineType,
                    valueKey: values.engineKey,
                    placeholder: l10n.filterEngineType,
                    optionKeys: _engineKeys,
                    resolveLabel: (key) => FilterL10n.engineLabel(l10n, key),
                    onSelected: (key) =>
                        onChanged(values.copyWith(engineKey: key)),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),
          _FilterFooter(
            onClear: onClear,
            onShowResults: onShowResults,
            showLabel: l10n.showCarsCount(_formatCount(l10n, resultCount)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickLocation(BuildContext context) async {
    final picked = await showLocationPickerSheet(
      context,
      initialSelection: values.selectedLocationKeys,
    );
    if (picked != null) {
      onChanged(values.copyWith(selectedLocationKeys: picked));
    }
  }
}

class _FilterHeader extends StatelessWidget {
  const _FilterHeader({
    required this.selectedLocationKeys,
    required this.onLocationTap,
    this.onAdvancedSearchTap,
  });

  final Set<String> selectedLocationKeys;
  final VoidCallback onLocationTap;
  final VoidCallback? onAdvancedSearchTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Row(
      children: [
        TextButton(
          onPressed: onAdvancedSearchTap,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: AdvancedFilterWidget._textPrimary,
          ),
          child: Text(
            l10n.advancedSearch,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
        ),
        const Spacer(),
        _LocationChip(
          label: FilterL10n.selectedLocationsSummary(
            l10n,
            selectedLocationKeys,
          ),
          onTap: onLocationTap,
        ),
      ],
    );
  }
}

class _LocationChip extends StatefulWidget {
  const _LocationChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  State<_LocationChip> createState() => _LocationChipState();
}

class _LocationChipState extends State<_LocationChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: _hovered
                ? AdvancedFilterWidget._fill.withValues(alpha: 0.9)
                : AdvancedFilterWidget._fill,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 18,
                color: AdvancedFilterWidget._textPrimary.withValues(
                  alpha: _hovered ? 1 : 0.85,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AdvancedFilterWidget._textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: AdvancedFilterWidget._textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterDropdown extends StatefulWidget {
  const _FilterDropdown({
    required this.width,
    required this.label,
    required this.valueKey,
    required this.placeholder,
    required this.optionKeys,
    required this.resolveLabel,
    required this.onSelected,
    this.enabled = true,
  });

  final double width;
  final String label;
  final String? valueKey;
  final String placeholder;
  final List<String> optionKeys;
  final String Function(String key) resolveLabel;
  final ValueChanged<String> onSelected;
  final bool enabled;

  @override
  State<_FilterDropdown> createState() => _FilterDropdownState();
}

class _FilterDropdownState extends State<_FilterDropdown> {
  bool _pressed = false;

  Future<void> _openPicker() async {
    if (!widget.enabled) return;
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AdvancedFilterWidget._textPrimary,
                ),
              ),
            ),
            ...widget.optionKeys.asMap().entries.map((entry) {
              final i = entry.key;
              final key = entry.value;
              final selected = widget.valueKey == key ||
                  (widget.valueKey == null && i == 0);
              return ListTile(
                title: Text(widget.resolveLabel(key)),
                trailing: selected
                    ? const Icon(Icons.check_rounded, size: 20)
                    : null,
                onTap: () => Navigator.pop(ctx, key),
              );
            }),
          ],
        ),
      ),
    );
    if (picked != null) widget.onSelected(picked);
  }

  @override
  Widget build(BuildContext context) {
    final display = widget.valueKey != null
        ? widget.resolveLabel(widget.valueKey!)
        : widget.placeholder;
    final hasValue = widget.valueKey != null;

    final textColor = widget.enabled
        ? (hasValue
            ? AdvancedFilterWidget._textPrimary
            : AdvancedFilterWidget._textSecondary)
        : AdvancedFilterWidget._textSecondary.withValues(alpha: 0.55);

    return SizedBox(
      width: widget.width,
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel:
            widget.enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.enabled ? _openPicker : null,
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1,
          duration: const Duration(milliseconds: 100),
          child: Container(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 12, 14),
            decoration: BoxDecoration(
              color: AdvancedFilterWidget._fill,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AdvancedFilterWidget._textSecondary,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        display,
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
      ),
    );
  }
}

class _FilterFooter extends StatelessWidget {
  const _FilterFooter({
    required this.onClear,
    required this.onShowResults,
    required this.showLabel,
  });

  final VoidCallback onClear;
  final VoidCallback onShowResults;
  final String showLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(
            onPressed: onClear,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: AdvancedFilterWidget._textSecondary,
            ),
            child: Text(
              l10n.clearFilters,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
                decorationThickness: 1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _PrimaryShowButton(label: showLabel, onTap: onShowResults),
      ],
    );
  }
}

class _PrimaryShowButton extends StatefulWidget {
  const _PrimaryShowButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  State<_PrimaryShowButton> createState() => _PrimaryShowButtonState();
}

class _PrimaryShowButtonState extends State<_PrimaryShowButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1,
          duration: const Duration(milliseconds: 120),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: _hovered || _pressed
                  ? Colors.black
                  : AdvancedFilterWidget._textPrimary,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: _hovered ? 0.2 : 0.12),
                  blurRadius: _hovered ? 20 : 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Text(
              widget.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
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
