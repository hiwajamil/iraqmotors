import 'package:flutter/material.dart';

import '../../../core/l10n_extensions.dart';
import '../../../data/add_car_form_options.dart';
import '../../../widgets/add_car_chip_selector.dart';

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
              'en' => 'Interior details',
              'ar' => 'تفاصيل الداخلية',
              _ => 'وردەکاریەکانی ناوەوە',
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
