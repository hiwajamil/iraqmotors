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

  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AddCarTheme.cardBg,
      elevation: 24,
      shadowColor: Colors.black.withValues(alpha: 0.12),
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
              color: const Color(0xFFFF9500).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              size: 32,
              color: Color(0xFFFF9500),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'تکایە وێنەکان چاک بکە',
            textAlign: TextAlign.center,
            style: AddCarTheme.sectionTitle.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AddCarTheme.stepSubtitle.copyWith(fontSize: 16),
          ),
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: AddCarTheme.primaryBlack,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'تێگەیشتم',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
