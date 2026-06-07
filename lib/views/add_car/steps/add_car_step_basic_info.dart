import 'package:flutter/material.dart';

import '../../../data/add_car_form_options.dart';
import '../../../data/car_models_by_brand.dart';
import '../../../data/dummy_brands.dart';
import '../../../models/car_brand.dart';
import '../../../widgets/brand_search_sheet.dart';

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
  });

  final String? brandId;
  final String? modelKey;
  final String? colorKey;
  final String? year;
  final String? trim;
  final ValueChanged<CarBrand> onBrandChanged;
  final ValueChanged<String> onModelChanged;
  final ValueChanged<String> onColorChanged;
  final ValueChanged<String> onYearChanged;
  final ValueChanged<String> onTrimChanged;

  static const Color _textPrimary = Color(0xFF1D1D1F);
  static const Color _textSecondary = Color(0xFF86868B);

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
      title: 'مۆدێل',
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'ڕەنگ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE5E5EA)),
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
                          color: _textPrimary,
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
      title: 'ساڵی مۆدێل',
      options: AddCarFormOptions.years,
      selected: year,
    );
    if (result != null) onYearChanged(result);
  }

  Future<void> _openTrimPicker(BuildContext context) async {
    final result = await _openStringSheet(
      context,
      title: 'خاسڵەت',
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
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
                    color: _textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE5E5EA)),
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
                          color: _textPrimary,
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
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
                    color: _textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE5E5EA)),
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
                          color: _textPrimary,
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
          const Text(
            'زانیاری سەرەتایی ئۆتۆمبێل',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.6,
              height: 1.15,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'ئەو زانیارییانە هەڵبژێرە کە لەگەڵ ئۆتۆمبێلەکەت دەگونجێت',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w400,
              height: 1.4,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 28),
          _AddCarSelectorField(
            label: 'براند',
            showAiBadge: true,
            value: brandLabel,
            placeholder: 'براند هەڵبژێرە',
            aiFilled: brandLabel != null,
            onTap: () => _openBrandPicker(context),
          ),
          const SizedBox(height: 14),
          _AddCarSelectorField(
            label: 'مۆدێل',
            value: modelLabel,
            placeholder: 'مۆدێل هەڵبژێرە',
            enabled: brand != null &&
                (CarModelsByBrand.modelsForBrand(brand)?.isNotEmpty ?? false),
            onTap: () => _openModelPicker(context),
          ),
          const SizedBox(height: 14),
          _AddCarSelectorField(
            label: 'ڕەنگ',
            value: colorLabel,
            placeholder: 'ڕەنگ هەڵبژێرە',
            trailing: colorSwatch != null
                ? _ColorDot(color: colorSwatch)
                : null,
            onTap: () => _openColorPicker(context),
          ),
          const SizedBox(height: 14),
          _AddCarSelectorField(
            label: 'ساڵی مۆدێل',
            value: year,
            placeholder: 'ساڵ هەڵبژێرە',
            onTap: () => _openYearPicker(context),
          ),
          const SizedBox(height: 14),
          _AddCarSelectorField(
            label: 'خاسڵەت',
            value: trim,
            placeholder: 'خاسڵەت هەڵبژێرە',
            onTap: () => _openTrimPicker(context),
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
        : Colors.grey.shade200;

    final textColor = widget.enabled
        ? (hasValue
            ? AddCarStepBasicInfo._textPrimary
            : AddCarStepBasicInfo._textSecondary)
        : AddCarStepBasicInfo._textSecondary.withValues(alpha: 0.45);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AddCarStepBasicInfo._textPrimary,
                letterSpacing: -0.2,
              ),
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
                    : Colors.grey.shade200.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(14),
                border: widget.showAiBadge && widget.aiFilled
                    ? Border.all(
                        color: AddCarFormOptions.aiAccentText.withValues(
                          alpha: 0.2,
                        ),
                      )
                    : null,
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
