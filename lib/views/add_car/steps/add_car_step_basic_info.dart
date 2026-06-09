import 'package:flutter/material.dart';

import '../../../core/l10n_extensions.dart';
import '../../../data/add_car_form_options.dart';
import '../../../data/car_models_by_brand.dart';
import '../../../data/dummy_brands.dart';
import '../../../models/car_brand.dart';
import '../../../widgets/brand_search_sheet.dart';
import '../add_car_theme.dart';
import '../widgets/add_car_form_card.dart';
import '../widgets/add_car_step_header.dart';

/// Step 3 — brand, model, color, year, and trim.
class AddCarStepBasicInfo extends StatelessWidget {
  const AddCarStepBasicInfo({
    super.key,
    required this.brandId,
    required this.modelKey,
    required this.colorKey,
    required this.year,
    required this.trim,
    required this.onBrandChanged,
    required this.onModelChanged,
    required this.onColorChanged,
    required this.onYearChanged,
    required this.onTrimChanged,
    this.isAnalyzingAi = false,
    this.aiFilledFields = const {},
  });

  final String? brandId;
  final String? modelKey;
  final String? colorKey;
  final String? year;
  final String? trim;
  final bool isAnalyzingAi;
  final Set<String> aiFilledFields;
  final ValueChanged<CarBrand> onBrandChanged;
  final ValueChanged<String> onModelChanged;
  final ValueChanged<String> onColorChanged;
  final ValueChanged<String> onYearChanged;
  final ValueChanged<String> onTrimChanged;

  CarBrand? get _brand {
    if (brandId == null) return null;
    for (final brand in dummyBrands) {
      if (brand.id == brandId) return brand;
    }
    return null;
  }

  Future<void> _openBrandPicker(BuildContext context) async {
    final brand = await BrandSearchSheet.show(context);
    if (brand != null) onBrandChanged(brand);
  }

  Future<void> _openModelPicker(BuildContext context) async {
    final brand = _brand;
    if (brand == null) return;

    final models = CarModelsByBrand.modelsForBrand(brand);
    if (models == null || models.isEmpty) return;

    final languageCode = Localizations.localeOf(context).languageCode;
    final result = await _openOptionSheet(
      context,
      title: context.l10n.addCarModelLabel,
      options: models,
      selectedId: modelKey,
      labelFor: (model) => model.labelFor(languageCode),
      idFor: (model) => model.id,
    );

    if (result != null) onModelChanged(result.id);
  }

  Future<void> _openColorPicker(BuildContext context) async {
    final languageCode = Localizations.localeOf(context).languageCode;
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AddCarTheme.cardBg,
      shape: AddCarTheme.bottomSheetShape,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  context.l10n.addCarColorLabel,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AddCarTheme.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const Divider(height: 1, color: AddCarTheme.border),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: AddCarFormOptions.colorKeys.length,
                  itemBuilder: (context, index) {
                    final key = AddCarFormOptions.colorKeys[index];
                    final isSelected = key == colorKey;
                    final swatch = AddCarFormOptions.swatchForKey(key);
                    return ListTile(
                      leading: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: swatch,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.black.withValues(alpha: 0.12),
                          ),
                        ),
                      ),
                      title: Text(
                        AddCarFormOptions.colorLabel(key, languageCode),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: AddCarTheme.textPrimary,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_rounded, size: 20)
                          : null,
                      onTap: () => Navigator.pop(ctx, key),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (result != null) onColorChanged(result);
  }

  Future<void> _openYearPicker(BuildContext context) async {
    final result = await _openStringSheet(
      context,
      title: context.l10n.addCarYearLabel,
      options: AddCarFormOptions.years,
      selected: year,
    );
    if (result != null) onYearChanged(result);
  }

  Future<void> _openTrimPicker(BuildContext context) async {
    final result = await _openStringSheet(
      context,
      title: context.l10n.addCarTrimLabel,
      options: AddCarFormOptions.trims,
      selected: trim,
    );
    if (result != null) onTrimChanged(result);
  }

  Future<T?> _openOptionSheet<T extends Object>(
    BuildContext context, {
    required String title,
    required List<T> options,
    required String? selectedId,
    required String Function(T) labelFor,
    required String Function(T) idFor,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: AddCarTheme.cardBg,
      shape: AddCarTheme.bottomSheetShape,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AddCarTheme.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const Divider(height: 1, color: AddCarTheme.border),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final isSelected = idFor(option) == selectedId;
                    return ListTile(
                      title: Text(
                        labelFor(option),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: AddCarTheme.textPrimary,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_rounded, size: 20)
                          : null,
                      onTap: () => Navigator.pop(ctx, option),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _openStringSheet(
    BuildContext context, {
    required String title,
    required List<String> options,
    required String? selected,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: AddCarTheme.cardBg,
      shape: AddCarTheme.bottomSheetShape,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AddCarTheme.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const Divider(height: 1, color: AddCarTheme.border),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final isSelected = option == selected;
                    return ListTile(
                      title: Text(
                        option,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: AddCarTheme.textPrimary,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_rounded, size: 20)
                          : null,
                      onTap: () => Navigator.pop(ctx, option),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final languageCode = Localizations.localeOf(context).languageCode;
    final brand = _brand;

    final brandLabel = brand?.displayName(languageCode);
    final modelLabel = brand != null && modelKey != null
        ? CarModelsByBrand.labelForModel(brand, modelKey!, languageCode)
        : null;
    final colorLabel = colorKey != null
        ? AddCarFormOptions.colorLabel(colorKey!, languageCode)
        : null;
    final colorSwatch = colorKey != null
        ? AddCarFormOptions.swatchForKey(colorKey!)
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AddCarStepHeader(
            title: l10n.addCarBasicInfoHeading,
            subtitle: l10n.addCarBasicInfoSubtitle,
          ),
          if (isAnalyzingAi) ...[
            const SizedBox(height: 12),
            const _AiAnalyzingInlineChip(),
          ],
          const SizedBox(height: 28),
          AddCarFormCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _AddCarSelectorField(
                  label: l10n.addCarBrandLabel,
                  showAiBadge: true,
                  value: brandLabel,
                  placeholder: l10n.addCarBrandPlaceholder,
                  aiFilled: aiFilledFields.contains('brandId') && brandLabel != null,
                  onTap: () => _openBrandPicker(context),
                ),
                const SizedBox(height: 14),
                _AddCarSelectorField(
                  label: l10n.addCarModelLabel,
                  showAiBadge: aiFilledFields.contains('modelKey'),
                  value: modelLabel,
                  placeholder: l10n.addCarModelPlaceholder,
                  aiFilled: aiFilledFields.contains('modelKey') && modelLabel != null,
                  enabled: brand != null &&
                      (CarModelsByBrand.modelsForBrand(brand)?.isNotEmpty ??
                          false),
                  onTap: () => _openModelPicker(context),
                ),
                const SizedBox(height: 14),
                _AddCarSelectorField(
                  label: l10n.addCarColorLabel,
                  showAiBadge: aiFilledFields.contains('colorKey'),
                  value: colorLabel,
                  placeholder: l10n.addCarColorPlaceholder,
                  aiFilled: aiFilledFields.contains('colorKey') && colorLabel != null,
                  trailing: colorSwatch != null
                      ? _ColorDot(color: colorSwatch)
                      : null,
                  onTap: () => _openColorPicker(context),
                ),
                const SizedBox(height: 14),
                _AddCarSelectorField(
                  label: l10n.addCarYearLabel,
                  value: year,
                  placeholder: l10n.addCarYearPlaceholder,
                  onTap: () => _openYearPicker(context),
                ),
                const SizedBox(height: 14),
                _AddCarSelectorField(
                  label: l10n.addCarTrimLabel,
                  value: trim,
                  placeholder: l10n.addCarTrimPlaceholder,
                  onTap: () => _openTrimPicker(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddCarSelectorField extends StatefulWidget {
  const _AddCarSelectorField({
    required this.label,
    required this.placeholder,
    required this.onTap,
    this.value,
    this.enabled = true,
    this.showAiBadge = false,
    this.aiFilled = false,
    this.trailing,
  });

  final String label;
  final String? value;
  final String placeholder;
  final VoidCallback onTap;
  final bool enabled;
  final bool showAiBadge;
  final bool aiFilled;
  final Widget? trailing;

  @override
  State<_AddCarSelectorField> createState() => _AddCarSelectorFieldState();
}

class _AddCarSelectorFieldState extends State<_AddCarSelectorField> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.value != null && widget.value!.isNotEmpty;
    final fillColor = widget.showAiBadge && widget.aiFilled
        ? AddCarFormOptions.aiAccentFill
        : AddCarTheme.inputFill;

    final textColor = widget.enabled
        ? (hasValue ? AddCarTheme.textPrimary : AddCarTheme.textSecondary)
        : AddCarTheme.textSecondary.withValues(alpha: 0.45);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              widget.label,
              style: AddCarTheme.sectionLabel,
            ),
            if (widget.showAiBadge) ...[
              const SizedBox(width: 8),
              const _AiBadge(),
            ],
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel:
              widget.enabled ? () => setState(() => _pressed = false) : null,
          onTap: widget.enabled ? widget.onTap : null,
          child: AnimatedScale(
            scale: _pressed ? 0.98 : 1,
            duration: const Duration(milliseconds: 100),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 12, 14),
              decoration: BoxDecoration(
                color: widget.enabled
                    ? fillColor
                    : AddCarTheme.inputFill.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(AddCarTheme.inputRadius),
                border: Border.all(
                  color: _pressed
                      ? AddCarTheme.focusBlue
                      : (widget.showAiBadge && widget.aiFilled
                          ? AddCarFormOptions.aiAccentText.withValues(alpha: 0.25)
                          : AddCarTheme.border),
                  width: _pressed ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  if (widget.trailing != null) ...[
                    widget.trailing!,
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      hasValue ? widget.value! : widget.placeholder,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            hasValue ? FontWeight.w600 : FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 24,
                    color: textColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AiAnalyzingInlineChip extends StatelessWidget {
  const _AiAnalyzingInlineChip();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AddCarFormOptions.aiAccentFill,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AddCarFormOptions.aiAccentText.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'AI analyzing...',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AddCarFormOptions.aiAccentText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiBadge extends StatelessWidget {
  const _AiBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AddCarFormOptions.aiAccentFill,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'AI',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AddCarFormOptions.aiAccentText,
              letterSpacing: 0.2,
            ),
          ),
          SizedBox(width: 2),
          Text(
            '✨',
            style: TextStyle(fontSize: 11, height: 1),
          ),
        ],
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.15),
        ),
      ),
    );
  }
}
