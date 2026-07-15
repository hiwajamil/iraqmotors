import 'package:flutter/material.dart';

import 'package:iq_motors/core/localization/l10n_extensions.dart';
import 'package:iq_motors/l10n/app_localizations.dart';

/// Minimal animated count of the cars currently shown in the home feed.
class HomeResultsCounter extends StatelessWidget {
  const HomeResultsCounter({
    super.key,
    required this.count,
    this.heroStyle = false,
  });

  final int count;
  final bool heroStyle;

  static String _formatCount(AppLocalizations l10n, int n) {
    if (l10n.localeName.startsWith('en')) {
      return n.toString();
    }
    const eastern = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((d) {
      final i = int.tryParse(d);
      return i == null ? d : eastern[i];
    }).join();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = l10n.homeCarsAvailableCount(_formatCount(l10n, count));

    return Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.2),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: Container(
          key: ValueKey<int>(count),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: heroStyle
                  ? Colors.black.withValues(alpha: 0.08)
                  : const Color(0xFF86868B).withValues(alpha: 0.18),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
              height: 1.2,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
