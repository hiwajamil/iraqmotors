import 'package:flutter/material.dart';
import 'package:iq_motors/core/localization/l10n_extensions.dart';
import 'package:iq_motors/core/theme/app_theme.dart';

/// Top bar with back button & title for AuthScreen.
class AuthTopNav extends StatelessWidget {
  const AuthTopNav({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 12),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              foregroundColor: context.colorScheme.onSurface,
            ),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
            label: Text(l10n.back),
          ),
          Expanded(
            child: Text(
              l10n.appTitle,
              textAlign: TextAlign.center,
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: context.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 80),
        ],
      ),
    );
  }
}

/// Header title & subtitle for Auth screen.
class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    required this.isLoginMode,
  });

  final bool isLoginMode;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    return Column(
      children: [
        Text(
          isLoginMode ? l10n.signIn : l10n.createAccount,
          textAlign: TextAlign.center,
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isLoginMode ? l10n.signInSubtitle : l10n.registerSubtitle,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

enum AccountTypeSelection { individual, showroom }

/// Segmented account type selector (Individual vs Showroom).
class AccountTypeToggle extends StatelessWidget {
  const AccountTypeToggle({
    super.key,
    required this.selection,
    required this.onChanged,
  });

  final AccountTypeSelection selection;
  final ValueChanged<AccountTypeSelection> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<AccountTypeSelection>(
        segments: [
          ButtonSegment(
            value: AccountTypeSelection.individual,
            label: Text(l10n.accountIndividual),
          ),
          ButtonSegment(
            value: AccountTypeSelection.showroom,
            label: Text(l10n.accountShowroom),
          ),
        ],
        selected: {selection},
        onSelectionChanged: (next) {
          if (next.isEmpty) return;
          onChanged(next.first);
        },
        showSelectedIcon: false,
        style: const ButtonStyle(
          visualDensity: VisualDensity.standard,
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
    );
  }
}
