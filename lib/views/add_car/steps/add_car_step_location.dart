import 'package:flutter/material.dart';

import '../../../widgets/iraq_location_dropdowns.dart';

/// Step 1 — governorate and city selection.
class AddCarStepLocation extends StatelessWidget {
  const AddCarStepLocation({
    super.key,
    required this.province,
    required this.city,
    required this.onProvinceChanged,
    required this.onCityChanged,
  });

  final String? province;
  final String? city;
  final ValueChanged<String> onProvinceChanged;
  final ValueChanged<String> onCityChanged;

  static const Color _textPrimary = Color(0xFF1D1D1F);
  static const Color _textSecondary = Color(0xFF86868B);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'ئۆتۆمبێلەکەت لە چ شوێنێکە؟',
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
            'پارێزگا / ناوچە دیاری بکە',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w400,
              height: 1.4,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          IraqLocationDropdowns(
            province: province,
            city: city,
            onProvinceChanged: onProvinceChanged,
            onCityChanged: onCityChanged,
          ),
        ],
      ),
    );
  }
}
