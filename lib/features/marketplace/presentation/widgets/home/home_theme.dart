import 'package:flutter/material.dart';

/// Shared colors for the home / explore screen.
abstract final class HomeScreenColors {
  static const Color background = Color(0xFFF5F5F7);
  static const Color textPrimary = Color(0xFF1D1D1F);
  static const Color textSecondary = Color(0xFF86868B);
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
      padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
                height: 1.2,
                color: HomeScreenColors.textPrimary,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
