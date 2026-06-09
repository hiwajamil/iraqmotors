import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/l10n_extensions.dart';
import '../../../data/add_car_form_options.dart';
import '../../../widgets/add_car_chip_selector.dart';
import '../add_car_theme.dart';
import '../widgets/add_car_form_card.dart';
import '../widgets/add_car_step_header.dart';

/// Step 5 — mileage and fuel type.
class AddCarStepMileageFuel extends StatefulWidget {
  const AddCarStepMileageFuel({
    super.key,
    required this.mileageValue,
    required this.mileageUnit,
    required this.fuelKey,
    required this.onMileageChanged,
    required this.onMileageUnitChanged,
    required this.onFuelChanged,
  });

  final String? mileageValue;
  final String mileageUnit;
  final String? fuelKey;
  final ValueChanged<String> onMileageChanged;
  final ValueChanged<String> onMileageUnitChanged;
  final ValueChanged<String> onFuelChanged;

  @override
  State<AddCarStepMileageFuel> createState() => _AddCarStepMileageFuelState();
}

class _AddCarStepMileageFuelState extends State<AddCarStepMileageFuel> {
  late final TextEditingController _mileageController;

  @override
  void initState() {
    super.initState();
    _mileageController = TextEditingController(text: widget.mileageValue ?? '');
  }

  @override
  void didUpdateWidget(AddCarStepMileageFuel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mileageValue != oldWidget.mileageValue &&
        widget.mileageValue != _mileageController.text) {
      _mileageController.text = widget.mileageValue ?? '';
    }
  }

  @override
  void dispose() {
    _mileageController.dispose();
    super.dispose();
  }

  Future<void> _openUnitPicker(BuildContext context) async {
    final l10n = context.l10n;
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
                  switch (l10n.localeName.split('_').first) {
                    'en' => 'Unit',
                    'ar' => 'الوحدة',
                    _ => 'یەکە',
                  },
                  style: AddCarTheme.sectionLabel,
                ),
              ),
              const Divider(height: 1, color: AddCarTheme.border),
              ...AddCarFormOptions.mileageUnits.map((unit) {
                final isSelected = unit == widget.mileageUnit;
                return ListTile(
                  title: Text(
                    AddCarFormOptions.mileageUnitLabel(l10n, unit),
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
                  onTap: () => Navigator.pop(ctx, unit),
                );
              }),
            ],
          ),
        );
      },
    );

    if (result != null) widget.onMileageUnitChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = l10n.localeName.split('_').first;

    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AddCarStepHeader(
            title: switch (locale) {
              'en' => 'More details',
              'ar' => 'تفاصيل إضافية',
              _ => 'وردەکاریەکانیتر',
            },
            subtitle: switch (locale) {
              'en' => 'Select the correct details',
              'ar' => 'اختر التفاصيل الصحيحة',
              _ => 'وردەکاریە ڕاستەکان هەڵبژێرە',
            },
          ),
          const SizedBox(height: 32),
          Text(
            switch (locale) {
              'en' => 'Mileage',
              'ar' => 'المسافة المقطوعة',
              _ => 'ماوەی ڕۆیشتن',
            },
            style: AddCarTheme.sectionLabel,
          ),
          const SizedBox(height: 12),
          AddCarFormCard(
            padding: EdgeInsets.zero,
            child: _MileageInput(
              controller: _mileageController,
              unitLabel: AddCarFormOptions.mileageUnitLabel(l10n, widget.mileageUnit),
              onChanged: widget.onMileageChanged,
              onUnitTap: () => _openUnitPicker(context),
            ),
          ),
          const SizedBox(height: 28),
          AddCarSimpleChipSection(
            label: switch (locale) {
              'en' => 'Fuel',
              'ar' => 'الوقود',
              _ => 'سووتەمەنی',
            },
            chipKeys: AddCarFormOptions.fuelChipKeys,
            selectedKey: widget.fuelKey,
            onSelected: widget.onFuelChanged,
            labelFor: (key) => AddCarFormOptions.fuelLabel(l10n, key),
          ),
        ],
      ),
    );
  }
}

class _MileageInput extends StatelessWidget {
  const _MileageInput({
    required this.controller,
    required this.unitLabel,
    required this.onChanged,
    required this.onUnitTap,
  });

  final TextEditingController controller;
  final String unitLabel;
  final ValueChanged<String> onChanged;
  final VoidCallback onUnitTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AddCarTheme.cardRadius),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _ThousandsSeparatorInputFormatter(),
                ],
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AddCarTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
                decoration: InputDecoration(
                  hintText: '160,000',
                  hintStyle: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: AddCarTheme.textPrimary.withValues(alpha: 0.25),
                  ),
                  filled: true,
                  fillColor: AddCarTheme.inputFill,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: AddCarTheme.focusBlue, width: 1.5),
                  ),
                  contentPadding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                onChanged: onChanged,
              ),
            ),
            Material(
              color: AddCarTheme.inputFill,
              child: InkWell(
                onTap: onUnitTap,
                child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        unitLabel,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AddCarTheme.textPrimary,
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: AddCarTheme.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(',', '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(digits[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
