import 'package:flutter/material.dart';

import 'package:iq_motors/core/localization/l10n_extensions.dart';
import 'package:iq_motors/shared/data/add_car_form_options.dart';
import 'package:iq_motors/features/listings/presentation/widgets/add_car_chip_selector.dart';
import 'package:iq_motors/features/listings/presentation/widgets/add_car_step_header.dart';

/// Step 7 — seat material and seat count.
class AddCarStepInterior extends StatelessWidget {
  const AddCarStepInterior({
    super.key,
    required this.seatMaterialKey,
    required this.seatCountKey,
    required this.onSeatMaterialChanged,
    required this.onSeatCountChanged,
  });

  final String? seatMaterialKey;
  final String? seatCountKey;
  final ValueChanged<String> onSeatMaterialChanged;
  final ValueChanged<String> onSeatCountChanged;

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
              'en' => 'Interior details',
              'ar' => 'تفاصيل الداخلية',
              _ => 'وردەکاریەکانی ناوەوە',
            },
            subtitle: switch (locale) {
              'en' => 'Select the correct details',
              'ar' => 'اختر التفاصيل الصحيحة',
              _ => 'وردەکاریە ڕاستەکان هەڵبژێرە',
            },
          ),
          const SizedBox(height: 32),
          AddCarSimpleChipSection(
            label: switch (locale) {
              'en' => 'Seat material',
              'ar' => 'مادة المقعد',
              _ => 'ماددەی کورسی',
            },
            chipKeys: AddCarFormOptions.seatMaterialKeys,
            selectedKey: seatMaterialKey,
            onSelected: onSeatMaterialChanged,
            labelFor: (key) => AddCarFormOptions.seatMaterialLabel(l10n, key),
            fullWidth: true,
          ),
          const SizedBox(height: 28),
          AddCarSimpleChipSection(
            label: switch (locale) {
              'en' => 'Number of seats',
              'ar' => 'عدد المقاعد',
              _ => 'ژمارەی کورسییەکان',
            },
            chipKeys: AddCarFormOptions.seatCountKeys,
            selectedKey: seatCountKey,
            onSelected: onSeatCountChanged,
            labelFor: (key) => AddCarFormOptions.seatCountLabel(l10n, key),
            squareChips: true,
          ),
        ],
      ),
    );
  }
}
