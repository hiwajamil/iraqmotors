import 'package:flutter/material.dart';

/// Minimal landing page shown on the public production domain only.
class ComingSoonScreen extends StatefulWidget {
  const ComingSoonScreen({super.key});

  @override
  State<ComingSoonScreen> createState() => _ComingSoonScreenState();
}

class _ComingSoonScreenState extends State<ComingSoonScreen>
    with SingleTickerProviderStateMixin {
  static const Color _background = Colors.white;
  static const Color _textPrimary = Color(0xFF1D1D1F);
  static const Color _textSecondary = Color(0xFF86868B);

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
    return Scaffold(
      backgroundColor: _background,
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
                      style: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -1.4,
                        color: _textPrimary,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'بەمنزیکانە...',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.4,
                        color: _textSecondary,
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
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.2,
                    color: _textSecondary.withValues(alpha: 0.9),
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
