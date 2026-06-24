import 'package:flutter/material.dart';

import 'package:iq_motors/core/localization/l10n_extensions.dart';
import 'package:iq_motors/shared/data/add_car_form_options.dart';
import 'package:iq_motors/features/listings/presentation/widgets/add_car_chip_selector.dart';
import 'package:iq_motors/features/listings/presentation/widgets/add_car_step_header.dart';

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
              'en' => 'Plate type & city',
              'ar' => 'نوع اللوحة والمدينة',
              _ => 'جۆری تابلۆ و شار',
            },
            subtitle: switch (locale) {
              'en' => 'Select your plate information',
              'ar' => 'اختر معلومات لوحتك',
              _ => 'زانیاری تابلۆکەت هەڵبژێرە',
            },
          ),
          const SizedBox(height: 32),
          AddCarChipSection(
            label: switch (locale) {
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
            label: switch (locale) {
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
