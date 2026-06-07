import 'package:flutter/material.dart';

import '../../../core/l10n_extensions.dart';
import '../../../data/add_car_option_keys.dart';

/// Step 11 — boost package selection.
class AddCarStepPackages extends StatelessWidget {
  const AddCarStepPackages({
    super.key,
    required this.selectedPackageKey,
    required this.onPackageChanged,
  });

  final String? selectedPackageKey;
  final ValueChanged<String> onPackageChanged;

  static const Color _textPrimary = Color(0xFF1D1D1F);
  static const Color _textSecondary = Color(0xFF86868B);

  @override
  Widget build(BuildContext context) {
    final locale = context.l10n.localeName.split('_').first;

    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            switch (locale) {
              'en' => 'Choose listing type',
              'ar' => 'اختر نوع الإعلان',
              _ => 'هەڵبژاردنی جۆری بڵاوکردنەوە',
            },
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.6,
              height: 1.15,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          _PackageCard(
            title: switch (locale) {
              'en' => 'Boost',
              'ar' => 'تعزيز',
              _ => 'بووست',
            },
            price: '10,000',
            priceSuffix: switch (locale) {
              'en' => 'IQD',
              'ar' => 'د.ع',
              _ => 'د.ع',
            },
            subtitle: switch (locale) {
              'en' =>
                'Reach buyers across Iraq. Your listing stays active for 90 days.',
              'ar' =>
                'وصل إلى المشترين في جميع أنحاء العراق. يبقى إعلانك نشطاً لمدة 90 يوماً.',
              _ =>
                'گەیشتن بە کڕیاران لە سەرانسەری عێراق. ڕاگەیاندنەکەت بۆ ماوەی ٩٠ ڕۆژ چالاک دەمێنێتەوە.',
            },
            selected: selectedPackageKey == AddCarOptionKeys.packageBoost,
            onTap: () => onPackageChanged(AddCarOptionKeys.packageBoost),
          ),
          const SizedBox(height: 14),
          _PackageCard(
            title: switch (locale) {
              'en' => 'Super Boost',
              'ar' => 'سوبر تعزيز',
              _ => 'سوپەر بووست',
            },
            price: '60,000',
            priceSuffix: switch (locale) {
              'en' => 'IQD',
              'ar' => 'د.ع',
              _ => 'د.ع',
            },
            subtitle: switch (locale) {
              'en' =>
                'Top search ranking across Iraq with up to 13× more views.',
              'ar' =>
                'أعلى ترتيب في البحث في العراق مع ما يصل إلى 13× مشاهدات أكثر.',
              _ =>
                'پلە سەرەکی گەڕان لە سەرانسەری عێراق و تا ١٣× بینینی زیاتر.',
            },
            badgeLabel: switch (locale) {
              'en' => 'Most Popular',
              'ar' => 'الأكثر شعبية',
              _ => 'باوترین',
            },
            selected: selectedPackageKey == AddCarOptionKeys.packageSuperBoost,
            onTap: () => onPackageChanged(AddCarOptionKeys.packageSuperBoost),
          ),
        ],
      ),
    );
  }
}

class _PackageCard extends StatefulWidget {
  const _PackageCard({
    required this.title,
    required this.price,
    required this.priceSuffix,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.badgeLabel,
  });

  final String title;
  final String price;
  final String priceSuffix;
  final String subtitle;
  final String? badgeLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_PackageCard> createState() => _PackageCardState();
}

class _PackageCardState extends State<_PackageCard> {
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
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsetsDirectional.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.selected
                  ? AddCarStepPackages._textPrimary
                  : const Color(0xFFE5E5EA),
              width: widget.selected ? 2 : 1,
            ),
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: AddCarStepPackages._textPrimary,
                      ),
                    ),
                  ),
                  if (widget.badgeLabel != null)
                    Container(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AddCarStepPackages._textPrimary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.badgeLabel!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    widget.price,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      color: AddCarStepPackages._textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      widget.priceSuffix,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AddCarStepPackages._textSecondary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.selected
                          ? AddCarStepPackages._textPrimary
                          : Colors.transparent,
                      border: Border.all(
                        color: widget.selected
                            ? AddCarStepPackages._textPrimary
                            : const Color(0xFFC7C7CC),
                        width: 2,
                      ),
                    ),
                    child: widget.selected
                        ? const Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.subtitle,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  height: 1.45,
                  color: AddCarStepPackages._textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
