import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/l10n_extensions.dart';
import '../../../data/add_car_form_options.dart';
import '../../../widgets/add_car_chip_selector.dart';

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
  static const Color _textPrimary = Color(0xFF1D1D1F);
  static const Color _textSecondary = Color(0xFF86868B);

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
                  switch (l10n.localeName.split('_').first) {
                    'en' => 'Unit',
                    'ar' => 'الوحدة',
                    _ => 'یەکە',
                  },
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE5E5EA)),
              ...AddCarFormOptions.mileageUnits.map((unit) {
                final isSelected = unit == widget.mileageUnit;
                return ListTile(
                  title: Text(
                    AddCarFormOptions.mileageUnitLabel(l10n, unit),
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
          Text(
            switch (locale) {
              'en' => 'More details',
              'ar' => 'تفاصيل إضافية',
              _ => 'وردەکاریەکانیتر',
            },
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.6,
              height: 1.15,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            switch (locale) {
              'en' => 'Select the correct details',
              'ar' => 'اختر التفاصيل الصحيحة',
              _ => 'وردەکاریە ڕاستەکان هەڵبژێرە',
            },
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w400,
              height: 1.4,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            switch (locale) {
              'en' => 'Mileage',
              'ar' => 'المسافة المقطوعة',
              _ => 'ماوەی ڕۆیشتن',
            },
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),
          _MileageInput(
            controller: _mileageController,
            unitLabel: AddCarFormOptions.mileageUnitLabel(l10n, widget.mileageUnit),
            onChanged: widget.onMileageChanged,
            onUnitTap: () => _openUnitPicker(context),
          ),
          const SizedBox(height: 28),
          Text(
            switch (locale) {
              'en' => 'Fuel',
              'ar' => 'الوقود',
              _ => 'سووتەمەنی',
            },
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final key in AddCarFormOptions.fuelChipKeys)
                AddCarSelectChip(
                  label: AddCarFormOptions.fuelLabel(l10n, key),
                  selected: widget.fuelKey == key,
                  onTap: () => widget.onFuelChanged(key),
                ),
            ],
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

  static const Color _textPrimary = Color(0xFF1D1D1F);
  static const Color _border = Color(0xFFE5E5EA);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      clipBehavior: Clip.antiAlias,
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
                  color: _textPrimary,
                  letterSpacing: -0.5,
                ),
                decoration: InputDecoration(
                  hintText: '160,000',
                  hintStyle: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: _textPrimary.withValues(alpha: 0.25),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                onChanged: onChanged,
              ),
            ),
            Material(
              color: Colors.grey.shade200,
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
                          color: _textPrimary,
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: Color(0xFF86868B),
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
