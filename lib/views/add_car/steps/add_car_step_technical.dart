import 'package:flutter/material.dart';

import '../../../core/l10n_extensions.dart';
import '../../../data/add_car_form_options.dart';
import '../../../widgets/add_car_chip_selector.dart';

/// Step 6 — import country, transmission, cylinders, and engine size.
class AddCarStepTechnical extends StatelessWidget {
  const AddCarStepTechnical({
    super.key,
    required this.importCountryKey,
    required this.transmissionKey,
    required this.cylindersKey,
    required this.engineSizeKey,
    required this.onImportCountryChanged,
    required this.onTransmissionChanged,
    required this.onCylindersChanged,
    required this.onEngineSizeChanged,
  });

  final String? importCountryKey;
  final String? transmissionKey;
  final String? cylindersKey;
  final String? engineSizeKey;
  final ValueChanged<String> onImportCountryChanged;
  final ValueChanged<String> onTransmissionChanged;
  final ValueChanged<String> onCylindersChanged;
  final ValueChanged<String> onEngineSizeChanged;

  static const Color _textPrimary = Color(0xFF1D1D1F);
  static const Color _textSecondary = Color(0xFF86868B);

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
              'en' => 'Technical details',
              'ar' => 'التفاصيل التقنية',
              _ => 'وردەکاری تەکنیکی',
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
          AddCarChipSection(
            label: switch (locale) {
              'en' => 'Import country',
              'ar' => 'بلد الاستيراد',
              _ => 'وڵاتی هاوردە',
            },
            chipKeys: AddCarFormOptions.importCountryChipKeys,
            otherKeys: AddCarFormOptions.importCountryOtherKeys,
            selectedKey: importCountryKey,
            onSelected: onImportCountryChanged,
            labelFor: (key) => AddCarFormOptions.importCountryLabel(l10n, key),
          ),
          const SizedBox(height: 28),
          AddCarSimpleChipSection(
            label: switch (locale) {
              'en' => 'Transmission',
              'ar' => 'ناقل الحركة',
              _ => 'گێڕ',
            },
            chipKeys: AddCarFormOptions.transmissionChipKeys,
            selectedKey: transmissionKey,
            onSelected: onTransmissionChanged,
            labelFor: (key) => AddCarFormOptions.transmissionLabel(l10n, key),
          ),
          const SizedBox(height: 28),
          AddCarSimpleChipSection(
            label: switch (locale) {
              'en' => 'Cylinders',
              'ar' => 'الأسطوانات',
              _ => 'پستۆن',
            },
            chipKeys: AddCarFormOptions.cylinderChipKeys,
            selectedKey: cylindersKey,
            onSelected: onCylindersChanged,
            labelFor: (key) => AddCarFormOptions.cylindersLabel(l10n, key),
          ),
          const SizedBox(height: 28),
          AddCarSimpleChipSection(
            label: switch (locale) {
              'en' => 'Engine size',
              'ar' => 'حجم المحرك',
              _ => 'قەبارەی بزوێنەر',
            },
            chipKeys: AddCarFormOptions.engineSizeChipKeys,
            selectedKey: engineSizeKey,
            onSelected: onEngineSizeChanged,
            labelFor: (key) => AddCarFormOptions.engineSizeLabel(l10n, key),
          ),
        ],
      ),
    );
  }
}
