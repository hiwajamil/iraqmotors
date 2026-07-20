import 'package:flutter/material.dart';

import 'package:iq_motors/core/localization/l10n_extensions.dart';
import 'package:iq_motors/shared/data/add_car_option_keys.dart';
import 'package:iq_motors/core/theme/app_theme.dart';
import 'package:iq_motors/features/listings/presentation/add_car_theme.dart';
import 'package:iq_motors/features/listings/presentation/widgets/add_car_step_header.dart';

/// Step 12 — payment method selection.
class AddCarStepPayment extends StatelessWidget {
  const AddCarStepPayment({
    super.key,
    required this.paymentMethodKey,
    required this.onPaymentMethodChanged,
  });

  final String? paymentMethodKey;
  final ValueChanged<String> onPaymentMethodChanged;

  @override
  Widget build(BuildContext context) {
    final locale = context.l10n.localeName.split('_').first;

    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AddCarStepHeader(
            title: switch (locale) {
              'en' => 'Payment',
              'ar' => 'الدفع',
              _ => 'پارەدان',
            },
            subtitle: switch (locale) {
              'en' => 'Choose a payment method',
              'ar' => 'اختر طريقة الدفع',
              _ => 'ڕێگەی پارەدان هەڵبژێرە',
            },
          ),
          const SizedBox(height: 28),
          _PaymentMethodTile(
            title: switch (locale) {
              'en' => 'Debit Card',
              'ar' => 'بطاقة خصم',
              _ => 'کارتی دێبیت',
            },
            selected: paymentMethodKey == AddCarOptionKeys.paymentDebitCard,
            onTap: () => onPaymentMethodChanged(AddCarOptionKeys.paymentDebitCard),
            trailing: const _CardBrandLogos(),
          ),
          const SizedBox(height: 12),
          _PaymentMethodTile(
            title: switch (locale) {
              'en' => 'E-Wallet',
              'ar' => 'محفظة إلكترونية',
              _ => 'جزدانی ئەلیکترۆنی',
            },
            selected: paymentMethodKey == AddCarOptionKeys.paymentEWallet,
            onTap: () => onPaymentMethodChanged(AddCarOptionKeys.paymentEWallet),
            trailing: const _ZainCashLogo(),
          ),
          const SizedBox(height: 12),
          _PaymentMethodTile(
            title: switch (locale) {
              'en' => 'Pay with FIB',
              'ar' => 'الدفع عبر FIB',
              _ => 'پارە بدە بە FIB',
            },
            selected: paymentMethodKey == AddCarOptionKeys.paymentFib,
            onTap: () => onPaymentMethodChanged(AddCarOptionKeys.paymentFib),
            trailing: const _FibQrPreview(),
            expandTrailing: true,
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodTile extends StatefulWidget {
  const _PaymentMethodTile({
    required this.title,
    required this.selected,
    required this.onTap,
    required this.trailing,
    this.expandTrailing = false,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;
  final Widget trailing;
  final bool expandTrailing;

  @override
  State<_PaymentMethodTile> createState() => _PaymentMethodTileState();
}

class _PaymentMethodTileState extends State<_PaymentMethodTile> {
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsetsDirectional.all(16),
          decoration: AddCarTheme.cardDecoration(context).copyWith(
            border: Border.all(
              color: widget.selected
                  ? AddCarTheme.primary(context)
                  : AddCarTheme.border(context),
              width: widget.selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.selected
                          ? AddCarTheme.primary(context)
                          : Colors.transparent,
                      border: Border.all(
                        color: widget.selected
                            ? AddCarTheme.primary(context)
                            : AddCarTheme.border(context),
                        width: 2,
                      ),
                    ),
                    child: widget.selected
                        ? Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: context.colorScheme.onPrimary,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: context.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AddCarTheme.textPrimary(context),
                      ),
                    ),
                  ),
                  if (!widget.expandTrailing) widget.trailing,
                ],
              ),
              if (widget.expandTrailing) ...[
                const SizedBox(height: 14),
                widget.trailing,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CardBrandLogos extends StatelessWidget {
  const _CardBrandLogos();

  @override
  Widget build(BuildContext context) {
    // Official card-network colors — intentionally not theme-derived so the
    // badges stay recognizable regardless of app theme/brightness.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _BrandPill(label: 'VISA', color: const Color(0xFF1A1F71)),
        const SizedBox(width: 6),
        _BrandPill(label: 'MC', color: const Color(0xFFEB001B)),
      ],
    );
  }
}

class _BrandPill extends StatelessWidget {
  const _BrandPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: context.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ZainCashLogo extends StatelessWidget {
  const _ZainCashLogo();

  @override
  Widget build(BuildContext context) {
    // Official Zain Cash brand color — intentionally not theme-derived.
    const zainCashColor = Color(0xFF6B2D5B);
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: zainCashColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Zain Cash',
        style: context.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: zainCashColor,
        ),
      ),
    );
  }
}

class _FibQrPreview extends StatelessWidget {
  const _FibQrPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AddCarTheme.scaffoldBg(context),
        borderRadius: BorderRadius.circular(AddCarTheme.inputRadius),
        border: Border.all(color: AddCarTheme.border(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 88,
            height: 88,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              // QR codes must stay black-on-white to remain scannable in
              // both light and dark themes.
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.colorScheme.outlineVariant),
            ),
            child: CustomPaint(
              painter: _MockQrPainter(),
              size: const Size.square(72),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FIB',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AddCarTheme.textPrimary(context),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  switch (Localizations.localeOf(context).languageCode) {
                    'en' => 'Scan QR with First Iraqi Bank app',
                    'ar' => 'امسح QR بتطبيق المصرف العراقي الأول',
                    _ => 'QR بخوێنەرەوە لە ئەپی بانکی یەکەمی عێراق',
                  },
                  style: context.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                    color: AddCarTheme.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MockQrPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Mock QR pattern needs solid dark pixels; kept as an absolute color
    // rather than theme-derived (a real QR doesn't invert for dark mode).
    final paint = Paint()..color = Colors.black;
    const cell = 6.0;
    for (var row = 0; row < size.height / cell; row++) {
      for (var col = 0; col < size.width / cell; col++) {
        if ((row + col) % 3 == 0 || (row * col) % 7 == 0) {
          canvas.drawRect(
            Rect.fromLTWH(col * cell, row * cell, cell - 1, cell - 1),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
