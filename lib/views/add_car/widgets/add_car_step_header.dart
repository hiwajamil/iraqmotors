import 'package:flutter/material.dart';

import '../add_car_theme.dart';

/// Shared title + subtitle block for add-car steps.
class AddCarStepHeader extends StatelessWidget {
  const AddCarStepHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: AddCarTheme.stepTitle),
        const SizedBox(height: 10),
        Text(subtitle, style: AddCarTheme.stepSubtitle),
        if (trailing != null) ...[
          const SizedBox(height: 8),
          trailing!,
        ],
      ],
    );
  }
}
