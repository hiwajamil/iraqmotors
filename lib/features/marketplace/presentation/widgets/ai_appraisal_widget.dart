import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iq_motors/core/localization/l10n_extensions.dart';
import 'package:iq_motors/features/marketplace/data/services/car_appraisal_service.dart';
import 'package:iq_motors/shared/widgets/app_loading_indicator.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

/// Provides a singleton [CarAppraisalService] instance.
final carAppraisalServiceProvider = Provider<CarAppraisalService>(
  (_) => CarAppraisalService(),
);

// ---------------------------------------------------------------------------
// Button — tappable entry point shown on the details screen
// ---------------------------------------------------------------------------

/// Material 3 "Get AI Price Estimate" button for the car details screen.
class AiAppraisalButton extends ConsumerStatefulWidget {
  const AiAppraisalButton({
    super.key,
    required this.carData,
  });

  final Map<String, dynamic> carData;

  @override
  ConsumerState<AiAppraisalButton> createState() => _AiAppraisalButtonState();
}

class _AiAppraisalButtonState extends ConsumerState<AiAppraisalButton> {
  bool _loading = false;

  Future<void> _onTap() async {
    if (_loading) return;
    setState(() => _loading = true);

    final service = ref.read(carAppraisalServiceProvider);
    try {
      final result = await service.appraise(widget.carData);
      if (!mounted) return;
      await AiAppraisalSheet.show(context, result: result);
    } on CarAppraisalException catch (e) {
      if (!mounted) return;
      final colorScheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.labelLarge;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton.icon(
        onPressed: _loading ? null : _onTap,
        icon: _loading
            ? AppLoadingIndicator.compact(
                color: colorScheme.onSurface.withValues(alpha: 0.38),
              )
            : const Icon(Icons.auto_awesome_rounded, size: 20),
        label: Text(
          context.l10n.aiAppraisalButton,
          style: labelStyle,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Result Bottom Sheet
// ---------------------------------------------------------------------------

/// Displays the AI appraisal result in a Material 3 modal bottom sheet.
class AiAppraisalSheet extends StatelessWidget {
  const AiAppraisalSheet({super.key, required this.result});

  final CarAppraisalResult result;

  static Future<void> show(
    BuildContext context, {
    required CarAppraisalResult result,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => AiAppraisalSheet(result: result),
    );
  }

  (Color, Color, IconData) _confidenceStyle(ColorScheme scheme) {
    return switch (result.confidence) {
      'high' => (
          scheme.tertiary,
          scheme.onTertiaryContainer,
          Icons.verified_rounded,
        ),
      'low' => (
          scheme.error,
          scheme.onErrorContainer,
          Icons.info_outline_rounded,
        ),
      _ => (
          scheme.secondary,
          scheme.onSecondaryContainer,
          Icons.show_chart_rounded,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final (confidenceColor, _, confidenceIcon) = _confidenceStyle(colorScheme);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
              child: const Icon(Icons.auto_awesome_rounded),
            ),
            title: Text(
              l10n.aiAppraisalTitle,
              style: textTheme.titleLarge,
            ),
            subtitle: Text(
              l10n.aiAppraisalSubtitle,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 8),

          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    l10n.aiAppraisalEstimatedRange,
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    result.formattedRange,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Iraqi Dinar (IQD)',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          Chip(
            avatar: Icon(confidenceIcon, size: 18, color: confidenceColor),
            label: Text(
              '${l10n.aiAppraisalConfidence}: ${result.confidence.toUpperCase()}',
            ),
            side: BorderSide(color: confidenceColor.withValues(alpha: 0.4)),
            backgroundColor: confidenceColor.withValues(alpha: 0.12),
            labelStyle: textTheme.labelLarge?.copyWith(color: confidenceColor),
          ),

          if (result.reasoning.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              result.reasoning,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 16),

          Material(
            color: colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.aiAppraisalDisclaimer,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.aiAppraisalClose),
            ),
          ),
        ],
      ),
    );
  }
}
