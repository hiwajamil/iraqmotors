import 'package:flutter/material.dart';

import '../../../core/l10n_extensions.dart';
import '../../../models/add_car_draft.dart';
import '../add_car_review_summary.dart';

/// Step 10 — full listing review before publish.
class AddCarStepReview extends StatelessWidget {
  const AddCarStepReview({
    super.key,
    required this.draft,
    required this.onEditStep,
  });

  final AddCarDraft draft;
  final ValueChanged<int> onEditStep;

  static const Color _textPrimary = Color(0xFF1D1D1F);
  static const Color _textSecondary = Color(0xFF86868B);

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
          Text(
            switch (locale) {
              'en' => 'Review',
              'ar' => 'مراجعة',
              _ => 'پێداچوونەوە',
            },
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.6,
              height: 1.15,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            switch (locale) {
              'en' => 'Make sure all your car details are correct',
              'ar' => 'تأكد من صحة جميع تفاصيل سيارتك',
              _ => 'دڵنیابە کە هەموو تایبەتمەندییەکانی ئۆتۆمبێلەکەت ڕاستن',
            },
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w400,
              height: 1.4,
              color: _textSecondary,
            ),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E5EA)),
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  section.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AddCarStepReview._textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              TextButton(
                onPressed: onEdit,
                style: TextButton.styleFrom(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  editLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0071E3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < section.rows.length; i++) ...[
            if (i > 0)
              const Divider(height: 16, color: Color(0xFFF0F0F2)),
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
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AddCarStepReview._textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: Text(
            row.value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AddCarStepReview._textPrimary,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
