import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iq_motors/app/providers/currency_provider.dart';
import 'package:iq_motors/core/services/currency_service.dart';

class CurrencySwitcherButton extends ConsumerWidget {
  const CurrencySwitcherButton({
    super.key,
    required this.iconColor,
  });

  final Color iconColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(currencyModeProvider);
    final isUsd = mode == CurrencyMode.usd;

    return InkWell(
      onTap: () => ref.read(currencyModeProvider.notifier).toggleCurrency(),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: iconColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          isUsd ? '\$ USD' : 'د.ع IQD',
          style: TextStyle(
            color: iconColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}
