import 'package:flutter/material.dart';
import 'package:iq_motors/core/theme/app_theme.dart';
import 'package:iq_motors/shared/widgets/app_loading_indicator.dart';

/// Data class holding metric stats for the super admin panel.
class SuperAdminStatData {
  const SuperAdminStatData({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentBg,
    required this.accentFg,
    this.isLoading = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accentBg;
  final Color accentFg;
  final bool isLoading;
}

/// Super-admin metric overview stat card.
class SuperAdminStatCard extends StatelessWidget {
  const SuperAdminStatCard({
    super.key,
    required this.data,
  });

  final SuperAdminStatData data;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: data.accentBg,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(data.icon, size: 24, color: data.accentFg),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data.isLoading)
                  const AppLoadingIndicator.standard()
                else
                  Text(
                    data.value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  data.label,
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
