import 'package:flutter/material.dart';

import 'package:iq_motors/core/theme/app_theme.dart';

/// Shared M3 colors for the home / explore screen.
abstract final class HomeScreenColors {
  static Color background(BuildContext context) => context.colorScheme.surface;

  static Color textPrimary(BuildContext context) =>
      context.colorScheme.onSurface;

  static Color textSecondary(BuildContext context) =>
      context.colorScheme.onSurfaceVariant;
}

/// Section heading used above brand strip and listing grid on mobile.
class HomeSectionTitle extends StatelessWidget {
  const HomeSectionTitle({
    super.key,
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: context.colorScheme.onSurface,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
