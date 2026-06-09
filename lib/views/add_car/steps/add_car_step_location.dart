import 'package:flutter/material.dart';

import '../../../core/l10n_extensions.dart';
import '../../../widgets/iraq_location_dropdowns.dart';
import '../widgets/add_car_step_header.dart';

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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AddCarStepHeader(
            title: l10n.addCarLocationHeading,
            subtitle: l10n.addCarLocationSubtitle,
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
