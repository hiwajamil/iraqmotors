import 'package:flutter/material.dart';
import 'package:iq_motors/core/localization/l10n_extensions.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

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
                (f) => Chip(
                  side: BorderSide.none,
                  backgroundColor: colorScheme.surfaceContainerHigh,
                  avatar: Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  label: Text(
                    f,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 24),
      ],
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
