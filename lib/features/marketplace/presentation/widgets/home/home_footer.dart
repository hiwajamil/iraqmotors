import 'package:flutter/material.dart';

import 'package:iq_motors/core/localization/l10n_extensions.dart';
import 'package:iq_motors/features/marketplace/presentation/widgets/home/home_theme.dart';

/// Copyright footer for the home / explore screen.
class HomeFooter extends StatelessWidget {
  const HomeFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 40),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 20,
        vertical: 40,
      ),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFFE5E5EA)),
        ),
      ),
      child: Text(
        l10n.footerCopyright,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 14,
          color: HomeScreenColors.textSecondary,
        ),
      ),
    );
  }
}
