import 'package:flutter/material.dart';

import 'package:iq_motors/core/theme/app_theme.dart';

/// Minimal landing page shown on the public production domain only.
class ComingSoonScreen extends StatefulWidget {
  const ComingSoonScreen({super.key});

  @override
  State<ComingSoonScreen> createState() => _ComingSoonScreenState();
}

class _ComingSoonScreenState extends State<ComingSoonScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _taglineController;
  late final Animation<double> _taglineFade;

  @override
  void initState() {
    super.initState();
    _taglineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _taglineFade = CurvedAnimation(
      parent: _taglineController,
      curve: Curves.easeOut,
    );
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _taglineController.forward();
    });
  }

  @override
  void dispose() {
    _taglineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'IQ Motors',
                      style: textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: -1.4,
                        color: colorScheme.onSurface,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'بەمنزیکانە...',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.4,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 52),
              child: FadeTransition(
                opacity: _taglineFade,
                child: Text(
                  'هێز بە شێوازێکی سادە.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    letterSpacing: -0.2,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.9),
                    height: 1.45,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
