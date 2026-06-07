import 'package:flutter/material.dart';

import '../../../core/l10n_extensions.dart';
import '../../../data/add_car_form_options.dart';
import '../../../widgets/add_car_chip_selector.dart';

/// Step 4 — plate type and plate city.
class AddCarStepPlateInfo extends StatelessWidget {
  const AddCarStepPlateInfo({
    super.key,
    required this.plateTypeKey,
    required this.plateCityKey,
    required this.onPlateTypeChanged,
    required this.onPlateCityChanged,
  });

  final String? plateTypeKey;
  final String? plateCityKey;
  final ValueChanged<String> onPlateTypeChanged;
  final ValueChanged<String> onPlateCityChanged;

  static const Color _textPrimary = Color(0xFF1D1D1F);
  static const Color _textSecondary = Color(0xFF86868B);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            switch (l10n.localeName.split('_').first) {
              'en' => 'Plate type & city',
              'ar' => 'نوع اللوحة والمدينة',
              _ => 'جۆری تابلۆ و شار',
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
            switch (l10n.localeName.split('_').first) {
              'en' => 'Select your plate information',
              'ar' => 'اختر معلومات لوحتك',
              _ => 'زانیاری تابلۆکەت هەڵبژێرە',
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
            label: switch (l10n.localeName.split('_').first) {
              'en' => 'Plate type',
              'ar' => 'نوع اللوحة',
              _ => 'جۆری تابلۆ',
            },
            chipKeys: AddCarFormOptions.plateTypeChipKeys,
            otherKeys: AddCarFormOptions.plateTypeOtherKeys,
            selectedKey: plateTypeKey,
            onSelected: onPlateTypeChanged,
            labelFor: (key) => AddCarFormOptions.plateTypeLabel(l10n, key),
          ),
          const SizedBox(height: 28),
          AddCarChipSection(
            label: switch (l10n.localeName.split('_').first) {
              'en' => 'Plate city',
              'ar' => 'مدينة اللوحة',
              _ => 'شاری تابلۆ',
            },
            chipKeys: AddCarFormOptions.plateCityChipKeys,
            otherKeys: AddCarFormOptions.plateCityOtherKeys,
            selectedKey: plateCityKey,
            onSelected: onPlateCityChanged,
            labelFor: (key) => AddCarFormOptions.plateCityLabel(l10n, key),
          ),
        ],
      ),
    );
  }
}
