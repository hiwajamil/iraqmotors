import 'package:flutter/material.dart';

/// Shared loading spinner sizes used across the app.
enum AppLoadingSize {
  /// Buttons and dense inline UI (~18 logical px).
  compact,

  /// Default mid-size for image placeholders and inline sections (~24).
  standard,

  /// Full-page / overlay blockers (~36).
  large,
}

/// Theme-aware [CircularProgressIndicator] with consistent sizing.
///
/// Prefer named constructors so stroke width and dimensions stay uniform.
class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({
    super.key,
    this.size = AppLoadingSize.standard,
    this.color,
    this.value,
    this.strokeWidth,
  });

  /// Compact spinner for buttons and tight rows.
  const AppLoadingIndicator.compact({
    super.key,
    this.color,
    this.value,
  })  : size = AppLoadingSize.compact,
        strokeWidth = null;

  /// Standard mid-size spinner (default).
  const AppLoadingIndicator.standard({
    super.key,
    this.color,
    this.value,
  })  : size = AppLoadingSize.standard,
        strokeWidth = null;

  /// Large spinner for page overlays and publish blockers.
  const AppLoadingIndicator.large({
    super.key,
    this.color,
    this.value,
  })  : size = AppLoadingSize.large,
        strokeWidth = null;

  final AppLoadingSize size;
  final Color? color;
  final double? value;
  final double? strokeWidth;

  double get _dimension => switch (size) {
        AppLoadingSize.compact => 18,
        AppLoadingSize.standard => 24,
        AppLoadingSize.large => 36,
      };

  double get _stroke =>
      strokeWidth ??
      switch (size) {
        AppLoadingSize.compact => 2,
        AppLoadingSize.standard => 2,
        AppLoadingSize.large => 3,
      };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _dimension,
      height: _dimension,
      child: CircularProgressIndicator(
        strokeWidth: _stroke,
        color: color,
        value: value,
      ),
    );
  }
}

/// Centered [AppLoadingIndicator] for section / page loading states.
class AppLoadingCenter extends StatelessWidget {
  const AppLoadingCenter({
    super.key,
    this.size = AppLoadingSize.standard,
    this.color,
    this.padding,
  });

  final AppLoadingSize size;
  final Color? color;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final indicator = AppLoadingIndicator(size: size, color: color);
    final centered = Center(child: indicator);
    if (padding == null) return centered;
    return Padding(padding: padding!, child: centered);
  }
}
