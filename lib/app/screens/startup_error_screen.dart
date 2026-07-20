import 'package:flutter/material.dart';

import 'package:iq_motors/core/theme/app_theme.dart';

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
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: Builder(
        builder: (context) {
          final colorScheme = context.colorScheme;
          final textTheme = context.textTheme;
          return Scaffold(
            backgroundColor: colorScheme.surface,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SelectableText(
                  'IQ Motors could not start.\n\n$error'
                  '${stackTrace == null ? '' : '\n\n$stackTrace'}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
