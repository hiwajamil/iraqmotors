import 'package:flutter/material.dart';
import 'package:iq_motors/core/localization/l10n_extensions.dart';
import 'package:iq_motors/shared/data/add_car_form_options.dart';

/// Clean 4-chip specifications grid for car details.
class QuickSpecsGrid extends StatelessWidget {
  const QuickSpecsGrid({
    super.key,
    required this.data,
  });

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    final specs = [
      _SpecItem(
        icon: Icons.speed_rounded,
        label: l10n.specMileage,
        value: data['mileage'] as String? ?? '—',
      ),
      _SpecItem(
        icon: Icons.tune_rounded,
        label: l10n.specTransmission,
        value: data['transmission'] as String? ?? '—',
      ),
      _SpecItem(
        icon: Icons.bolt_rounded,
        label: l10n.specEngine,
        value: data['engine'] as String? ?? '—',
      ),
      _SpecItem(
        icon: Icons.location_on_outlined,
        label: l10n.specLocation,
        value: data['location'] as String? ?? '—',
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: specs.map((s) => Expanded(child: s)).toList(),
      ),
    );
  }
}

class _SpecItem extends StatelessWidget {
  const _SpecItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(height: 6),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

/// Feature pills section for car details.
class FeaturesSection extends StatelessWidget {
  const FeaturesSection({
    super.key,
    required this.features,
  });

  final List<String> features;

  static IconData _iconForFeature(String key) {
    return switch (key) {
      'feature_sunroof' => Icons.wb_sunny_outlined,
      'feature_panoramic_roof' => Icons.panorama_outlined,
      'feature_seat_heater' => Icons.airline_seat_recline_extra_rounded,
      'feature_steering_heater' => Icons.settings_remote_outlined,
      'feature_rear_camera' => Icons.camera_rear_outlined,
      'feature_radar_mirror' => Icons.radar_rounded,
      'feature_radar' => Icons.radar_rounded,
      'feature_parking_brake' => Icons.emergency_rounded,
      'feature_sensitive' => Icons.sensors_rounded,
      'feature_screen' => Icons.tv_rounded,
      'feature_electric_mirror' => Icons.electric_bolt_rounded,
      'feature_electric_seat' => Icons.chair_rounded,
      'feature_smart_key' => Icons.key_rounded,
      'feature_cruise_control' => Icons.speed_rounded,
      'feature_xenon_light' => Icons.highlight_rounded,
      'feature_auto_headlight' => Icons.lightbulb_rounded,
      'feature_speaker_8' => Icons.speaker_rounded,
      'feature_apple_carplay' => Icons.phone_iphone_rounded,
      'feature_abs' => Icons.directions_car_rounded,
      'feature_awd' => Icons.drive_eta_rounded,
      'feature_wireless_charger' => Icons.battery_charging_full_rounded,
      'feature_anti_theft' => Icons.lock_rounded,
      'feature_horn' => Icons.campaign_rounded,
      'feature_speed_sign' => Icons.sign_language_rounded,
      'feature_tire_pressure' => Icons.tire_repair_rounded,
      'feature_driver_attention' => Icons.remove_red_eye_rounded,
      _ => Icons.check_circle_outline_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.features,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: features
              .map(
                (f) => _FeatureChip(
                  icon: _iconForFeature(f),
                  label: AddCarFormOptions.featureLabel(l10n, f),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}


/// Technical specifications list card.
class FullSpecsCard extends StatelessWidget {
  const FullSpecsCard({
    super.key,
    required this.data,
  });

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final rows = <MapEntry<String, String>>[
      MapEntry(l10n.specYear, data['year'] as String? ?? '—'),
      MapEntry(l10n.specType, data['bodyType'] as String? ?? '—'),
      MapEntry(l10n.specColor, data['color'] as String? ?? '—'),
      MapEntry(l10n.specEngine, data['engine'] as String? ?? '—'),
      MapEntry(l10n.specTransmission, data['transmission'] as String? ?? '—'),
      MapEntry(l10n.specMileage, data['mileage'] as String? ?? '—'),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.technicalDetails,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    row.key,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    row.value,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
