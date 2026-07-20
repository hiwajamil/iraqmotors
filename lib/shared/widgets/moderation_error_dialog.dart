import 'package:flutter/material.dart';

import 'package:iq_motors/features/listings/presentation/add_car_theme.dart';

/// Shows a friendly dialog when the upload API rejects an image (HTTP 400).
Future<void> showModerationErrorDialog(
  BuildContext context,
  String reason,
) {
  final message = reason.trim().isNotEmpty
      ? reason.trim()
      : 'وێنەکە قبوڵ نەکرا. تکایە وێنەیەکی تر هەڵبژێرە.';

  final scheme = Theme.of(context).colorScheme;

  return showDialog<void>(
    context: context,
    barrierColor: scheme.scrim.withValues(alpha: 0.35),
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AddCarTheme.cardBg(context),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: scheme.tertiaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              size: 32,
              color: scheme.onTertiaryContainer,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'تکایە وێنەکان چاک بکە',
            textAlign: TextAlign.center,
            style: AddCarTheme.sectionTitle(context),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AddCarTheme.stepSubtitle(context),
          ),
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'تێگەیشتم',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onPrimary,
                  ),
            ),
          ),
        ),
      ],
    ),
  );
}
