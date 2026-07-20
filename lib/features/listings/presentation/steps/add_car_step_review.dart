import 'package:flutter/material.dart';

import 'package:iq_motors/core/localization/l10n_extensions.dart';
import 'package:iq_motors/features/listings/domain/models/add_car_draft.dart';
import 'package:iq_motors/features/listings/presentation/add_car_review_summary.dart';
import 'package:iq_motors/core/theme/app_theme.dart';
import 'package:iq_motors/features/listings/presentation/add_car_theme.dart';
import 'package:iq_motors/features/listings/presentation/widgets/add_car_form_card.dart';
import 'package:iq_motors/features/listings/presentation/widgets/add_car_step_header.dart';

/// Step 10 — full listing review before publish.
class AddCarStepReview extends StatelessWidget {
  const AddCarStepReview({
    super.key,
    required this.draft,
    required this.onEditStep,
  });

  final AddCarDraft draft;
  final ValueChanged<int> onEditStep;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = l10n.localeName.split('_').first;
    final sections = AddCarReviewSummary.build(l10n, draft);

    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AddCarStepHeader(
            title: switch (locale) {
              'en' => 'Review',
              'ar' => 'مراجعة',
              _ => 'پێداچوونەوە',
            },
            subtitle: switch (locale) {
              'en' => 'Make sure all your car details are correct',
              'ar' => 'تأكد من صحة جميع تفاصيل سيارتك',
              _ => 'دڵنیابە کە هەموو تایبەتمەندییەکانی ئۆتۆمبێلەکەت ڕاستن',
            },
          ),
          const SizedBox(height: 24),
          for (var i = 0; i < sections.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _ReviewSectionCard(
              section: sections[i],
              editLabel: switch (locale) {
                'en' => 'Edit',
                'ar' => 'تعديل',
                _ => 'گۆڕین',
              },
              onEdit: () => onEditStep(sections[i].stepIndex),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReviewSectionCard extends StatelessWidget {
  const _ReviewSectionCard({
    required this.section,
    required this.editLabel,
    required this.onEdit,
  });

  final AddCarReviewSection section;
  final String editLabel;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return AddCarFormCard(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  section.title,
                  style: context.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AddCarTheme.textPrimary(context),
                  ),
                ),
              ),
              TextButton(
                onPressed: onEdit,
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  foregroundColor: AddCarTheme.focus(context),
                ),
                child: Text(editLabel),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < section.rows.length; i++) ...[
            if (i > 0)
              Divider(height: 16, color: AddCarTheme.border(context)),
            _ReviewRow(row: section.rows[i]),
          ],
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.row});

  final AddCarReviewRow row;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            row.label,
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: AddCarTheme.textSecondary(context),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: Text(
            row.value,
            textAlign: TextAlign.end,
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AddCarTheme.textPrimary(context),
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
