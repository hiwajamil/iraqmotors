import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:iq_motors/core/localization/filter_l10n.dart';
import 'package:iq_motors/core/localization/l10n_extensions.dart';
import 'package:iq_motors/core/theme/app_theme.dart';
import 'package:iq_motors/shared/data/car_models_by_brand.dart';
import 'package:iq_motors/l10n/app_localizations.dart';
import 'package:iq_motors/features/marketplace/domain/models/advanced_filter_state.dart';
import 'package:iq_motors/shared/models/car_brand.dart';
import 'package:iq_motors/shared/widgets/filter_option_picker_dialog.dart';

/// Location + advanced search title row above the brands strip.
class AdvancedFilterHeader extends StatelessWidget {
  const AdvancedFilterHeader({
    super.key,
    required this.selectedLocationKeys,
    required this.onLocationTap,
    this.onAdvancedSearchTap,
    this.heroStyle = false,
  });

  final Set<String> selectedLocationKeys;
  final VoidCallback onLocationTap;
  final VoidCallback? onAdvancedSearchTap;
  final bool heroStyle;

  @override
  Widget build(BuildContext context) {
    return _FilterHeader(
      selectedLocationKeys: selectedLocationKeys,
      onLocationTap: onLocationTap,
      onAdvancedSearchTap: onAdvancedSearchTap,
      heroStyle: heroStyle,
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
  });

  final CarBrand? selectedBrand;
  final AdvancedFilterState values;
  final ValueChanged<AdvancedFilterState> onChanged;
  final VoidCallback onClear;
  final VoidCallback onShowResults;

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
    final colorScheme = context.colorScheme;
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
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
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
            showLabel: l10n.showCarsCount('…'),
          ),
        ],
      ),
    );
  }

}

class _FilterHeader extends StatelessWidget {
  const _FilterHeader({
    required this.selectedLocationKeys,
    required this.onLocationTap,
    this.onAdvancedSearchTap,
    this.heroStyle = false,
  });

  final Set<String> selectedLocationKeys;
  final VoidCallback onLocationTap;
  final VoidCallback? onAdvancedSearchTap;
  final bool heroStyle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = context.colorScheme;
    final isCompact = MediaQuery.sizeOf(context).width < 400;
    final primaryColor = heroStyle ? Colors.white : colorScheme.onSurface;
    final secondaryColor =
        heroStyle ? Colors.white70 : colorScheme.onSurfaceVariant;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 14 : 20,
        vertical: isCompact ? 12 : 16,
      ),
      decoration: heroStyle
          ? null
          : BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onAdvancedSearchTap,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.search,
                  size: 18,
                  color: primaryColor.withValues(alpha: heroStyle ? 0.9 : 0.7),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.advancedSearch,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontSize: isCompact ? 14 : 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: _LocationChip(
                label: FilterL10n.selectedLocationsSummary(
                  l10n,
                  selectedLocationKeys,
                ),
                onTap: onLocationTap,
                backgroundColor: heroStyle
                    ? Colors.white.withValues(alpha: 0.15)
                    : colorScheme.surfaceContainerHighest,
                foregroundColor: primaryColor,
                secondaryColor: secondaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationChip extends StatefulWidget {
  const _LocationChip({
    required this.label,
    required this.onTap,
    this.backgroundColor,
    this.foregroundColor,
    this.secondaryColor,
  });

  final String label;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? secondaryColor;

  @override
  State<_LocationChip> createState() => _LocationChipState();
}

class _LocationChipState extends State<_LocationChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final baseColor =
        widget.backgroundColor ?? colorScheme.surfaceContainerHighest;
    final textColor = widget.foregroundColor ?? colorScheme.onSurface;
    final mutedColor = widget.secondaryColor ?? colorScheme.onSurfaceVariant;

    return LayoutBuilder(
      builder: (context, constraints) {
        return MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              constraints: BoxConstraints(maxWidth: constraints.maxWidth),
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: _hovered
                    ? baseColor.withValues(alpha: 0.85)
                    : baseColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: textColor.withValues(alpha: _hovered ? 1 : 0.85),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: mutedColor,
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
  Future<void> _openPicker() async {
    if (!widget.enabled) return;
    final picked = await FilterOptionPickerDialog.show(
      context,
      title: widget.label,
      optionKeys: widget.optionKeys,
      resolveLabel: widget.resolveLabel,
      valueKey: widget.valueKey,
    );
    if (picked != null) widget.onSelected(picked);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final display = widget.valueKey != null
        ? widget.resolveLabel(widget.valueKey!)
        : widget.placeholder;
    final hasValue = widget.valueKey != null;

    final textColor = widget.enabled
        ? (hasValue ? colorScheme.onSurface : colorScheme.onSurfaceVariant)
        : colorScheme.onSurfaceVariant.withValues(alpha: 0.55);

    return SizedBox(
      width: widget.width,
      child: OutlinedButton(
        onPressed: widget.enabled ? _openPicker : null,
        style: OutlinedButton.styleFrom(
          alignment: AlignmentDirectional.centerStart,
          backgroundColor: colorScheme.surfaceContainerHighest,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 12, 14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.label,
              style: textTheme.labelSmall?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
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
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: hasValue ? FontWeight.w600 : FontWeight.w500,
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
              minimumSize: const Size(48, 48),
              foregroundColor: context.colorScheme.onSurfaceVariant,
            ),
            child: Text(l10n.clearFilters),
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
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: widget.onTap,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(widget.label),
      ),
    );
  }
}
