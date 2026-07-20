import 'package:flutter/material.dart';

import 'package:iq_motors/core/theme/app_theme.dart';

/// Sell / Add Car wizard tokens — always resolved from Material 3 theme.
abstract final class AddCarTheme {
  static const double cardRadius = 16;
  static const double inputRadius = 12;
  static const double pillRadius = 24;

  static Color scaffoldBg(BuildContext context) => context.colorScheme.surface;

  static Color cardBg(BuildContext context) =>
      context.colorScheme.surfaceContainerLowest;

  static Color inputFill(BuildContext context) =>
      context.colorScheme.surfaceContainerHighest;

  static Color focus(BuildContext context) => context.colorScheme.primary;

  static Color primary(BuildContext context) => context.colorScheme.primary;

  static Color textPrimary(BuildContext context) =>
      context.colorScheme.onSurface;

  static Color textSecondary(BuildContext context) =>
      context.colorScheme.onSurfaceVariant;

  static Color border(BuildContext context) =>
      context.colorScheme.outlineVariant;

  static Color success(BuildContext context) => context.colorScheme.tertiary;

  static BoxDecoration cardDecoration(
    BuildContext context, {
    Color? color,
  }) =>
      BoxDecoration(
        color: color ?? cardBg(context),
        borderRadius: BorderRadius.circular(cardRadius),
      );

  static BoxDecoration inputDecorationBox(
    BuildContext context, {
    Color? fillColor,
    bool focused = false,
    bool enabled = true,
  }) {
    final scheme = context.colorScheme;
    return BoxDecoration(
      color: enabled
          ? (fillColor ?? inputFill(context))
          : inputFill(context).withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(inputRadius),
      border: Border.all(
        color: focused ? scheme.primary : scheme.outlineVariant,
        width: focused ? 1.5 : 1,
      ),
    );
  }

  static TextStyle stepTitle(BuildContext context) =>
      context.textTheme.headlineMedium!.copyWith(
        fontWeight: FontWeight.w700,
        color: context.colorScheme.onSurface,
      );

  static TextStyle stepSubtitle(BuildContext context) =>
      context.textTheme.bodyLarge!.copyWith(
        color: context.colorScheme.onSurfaceVariant,
      );

  static TextStyle sectionTitle(BuildContext context) =>
      context.textTheme.headlineSmall!.copyWith(
        fontWeight: FontWeight.w700,
        color: context.colorScheme.onSurface,
      );

  static TextStyle sectionLabel(BuildContext context) =>
      context.textTheme.titleSmall!.copyWith(
        fontWeight: FontWeight.w600,
        color: context.colorScheme.onSurface,
      );

  static InputDecoration textFieldDecoration(
    BuildContext context, {
    String? hintText,
    String? prefixText,
  }) {
    final scheme = context.colorScheme;
    final texts = context.textTheme;
    return InputDecoration(
      hintText: hintText,
      hintStyle: texts.bodyLarge?.copyWith(
        color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
      ),
      prefixText: prefixText,
      prefixStyle: texts.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
      filled: true,
      fillColor: inputFill(context),
      contentPadding: const EdgeInsetsDirectional.all(16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputRadius),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputRadius),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputRadius),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
    );
  }

  static ShapeBorder get bottomSheetShape => const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      );
}
