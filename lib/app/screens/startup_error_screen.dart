import 'package:flutter/material.dart';

/// Shown when [main] fails before the normal app shell can start.
class StartupErrorScreen extends StatelessWidget {
  const StartupErrorScreen({
    super.key,
    required this.error,
    this.stackTrace,
  });

  final Object error;
  final StackTrace? stackTrace;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFFF5F5F7),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SelectableText(
              'IQ Motors could not start.\n\n$error'
              '${stackTrace == null ? '' : '\n\n$stackTrace'}',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1D1D1F),
                height: 1.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
