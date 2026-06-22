import 'package:flutter/material.dart';

import '../../../core/l10n_extensions.dart';
import '../../../data/add_car_form_options.dart';
import '../../../widgets/add_car_chip_selector.dart';
import '../widgets/add_car_step_header.dart';

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
              'en' => 'Technical details',
              'ar' => 'التفاصيل التقنية',
              _ => 'وردەکاری تەکنیکی',
            },
            subtitle: switch (locale) {
              'en' => 'Select the correct details',
              'ar' => 'اختر التفاصيل الصحيحة',
              _ => 'وردەکاریە ڕاستەکان هەڵبژێرە',
            },
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
            cardPadding: const EdgeInsetsDirectional.fromSTEB(10, 8, 10, 8),
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
            cardPadding: const EdgeInsetsDirectional.fromSTEB(10, 8, 10, 8),
          ),
        ],
      ),
    );
  }
}
