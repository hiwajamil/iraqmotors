import 'package:flutter/material.dart';

import '../../../core/l10n_extensions.dart';
import '../../../data/add_car_form_options.dart';
import '../../../widgets/add_car_chip_selector.dart';

/// Step 8 — paint/damage condition and extra features.
class AddCarStepConditionFeatures extends StatelessWidget {
  const AddCarStepConditionFeatures({
    super.key,
    required this.conditionKey,
    required this.selectedFeatures,
    required this.damagePhotoCount,
    required this.onConditionChanged,
    required this.onFeatureToggled,
    required this.onSelectAllFeatures,
    required this.onDamagePhotoAdded,
  });

  final String? conditionKey;
  final Set<String> selectedFeatures;
  final int damagePhotoCount;
  final ValueChanged<String> onConditionChanged;
  final ValueChanged<String> onFeatureToggled;
  final ValueChanged<bool> onSelectAllFeatures;
  final VoidCallback onDamagePhotoAdded;

  static const Color _textPrimary = Color(0xFF1D1D1F);
  static const Color _textSecondary = Color(0xFF86868B);

  bool get _allFeaturesSelected =>
      selectedFeatures.length >= AddCarFormOptions.featureKeys.length;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = l10n.localeName.split('_').first;

    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            switch (locale) {
              'en' => 'Painted panels',
              'ar' => 'القطع المطلية',
              _ => 'پارچەی بۆیاخکراو',
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
              'en' => 'Specify if your car has damaged panels',
              'ar' => 'حدد إذا كان لسيارتك قطع متضررة',
              _ => 'دیاریبکە ئەگەر ئۆتۆمبێلەکەت پارچەی زیانپێگەیشتووی هەیە',
            },
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w400,
              height: 1.4,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final key in AddCarFormOptions.conditionChipKeys)
                AddCarSelectChip(
                  label: AddCarFormOptions.conditionLabel(l10n, key),
                  selected: conditionKey == key,
                  onTap: () => onConditionChanged(key),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _DamagePhotoButton(
            label: switch (locale) {
              'en' => 'Take photos of damaged panels',
              'ar' => 'التقط صوراً للقطع المتضررة',
              _ => 'وێنەی پارچە زیانپێگەیشتووەکان بگرە',
            },
            photoCount: damagePhotoCount,
            onTap: onDamagePhotoAdded,
          ),
          const SizedBox(height: 36),
          Text(
            switch (locale) {
              'en' => 'Extra features',
              'ar' => 'ميزات إضافية',
              _ => 'تایبەتمەندی زیاتر',
            },
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          _SelectAllRow(
            label: switch (locale) {
              'en' => 'Select all features',
              'ar' => 'تحديد جميع الميزات',
              _ => 'هەڵبژاردنی هەموو تایبەتمەندییەکان',
            },
            value: _allFeaturesSelected,
            onChanged: onSelectAllFeatures,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final key in AddCarFormOptions.featureKeys)
                AddCarSelectChip(
                  label: AddCarFormOptions.featureLabel(l10n, key),
                  selected: selectedFeatures.contains(key),
                  onTap: () => onFeatureToggled(key),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DamagePhotoButton extends StatefulWidget {
  const _DamagePhotoButton({
    required this.label,
    required this.photoCount,
    required this.onTap,
  });

  final String label;
  final int photoCount;
  final VoidCallback onTap;

  @override
  State<_DamagePhotoButton> createState() => _DamagePhotoButtonState();
}

class _DamagePhotoButtonState extends State<_DamagePhotoButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E5EA)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.photo_camera_outlined,
                  size: 22,
                  color: AddCarStepConditionFeatures._textPrimary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AddCarStepConditionFeatures._textPrimary,
                  ),
                ),
              ),
              if (widget.photoCount > 0)
                Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AddCarStepConditionFeatures._textPrimary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${widget.photoCount}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectAllRow extends StatelessWidget {
  const _SelectAllRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E5EA)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AddCarStepConditionFeatures._textPrimary,
                  ),
                ),
              ),
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeTrackColor: AddCarStepConditionFeatures._textPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
