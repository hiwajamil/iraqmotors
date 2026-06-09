import 'package:flutter/material.dart';

/// Design tokens for the Sell / Add Car wizard only.
abstract final class AddCarTheme {
  static const Color scaffoldBg = Color(0xFFF5F5F7);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color inputFill = Color(0xFFFAFAFA);
  static const Color focusBlue = Color(0xFF007AFF);
  static const Color primaryBlack = Color(0xFF000000);
  static const Color textPrimary = Color(0xFF1D1D1F);
  static const Color textSecondary = Color(0xFF86868B);
  static const Color border = Color(0xFFE5E5EA);
  static const Color successGreen = Color(0xFF34C759);

  static const double cardRadius = 20;
  static const double inputRadius = 12;
  static const double pillRadius = 30;

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 24,
          offset: const Offset(0, 4),
        ),
      ];

  static BoxDecoration cardDecoration({Color? color}) => BoxDecoration(
        color: color ?? cardBg,
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: cardShadow,
      );

  static BoxDecoration inputDecorationBox({
    Color? fillColor,
    bool focused = false,
    bool enabled = true,
  }) =>
      BoxDecoration(
        color: enabled ? (fillColor ?? inputFill) : inputFill.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(inputRadius),
        border: Border.all(
          color: focused ? focusBlue : border,
          width: focused ? 1.5 : 1,
        ),
      );

  static TextStyle get stepTitle => const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        height: 1.15,
        color: textPrimary,
      );

  static TextStyle get stepSubtitle => const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: textSecondary,
      );

  static TextStyle get sectionTitle => const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: textPrimary,
      );

  static TextStyle get sectionLabel => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: -0.2,
      );

  static InputDecoration textFieldDecoration({
    String? hintText,
    String? prefixText,
  }) =>
      InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          fontSize: 16,
          color: textSecondary.withValues(alpha: 0.85),
        ),
        prefixText: prefixText,
        prefixStyle: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -1,
          color: textPrimary,
        ),
        filled: true,
        fillColor: inputFill,
        contentPadding: const EdgeInsetsDirectional.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: focusBlue, width: 1.5),
        ),
      );

  static ShapeBorder get bottomSheetShape => const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      );
}
