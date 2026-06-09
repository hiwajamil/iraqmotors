import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_localization_delegates.dart';
import 'core/firebase_web_config.dart';
import 'core/locale_config.dart';
import 'providers/locale_provider.dart';
import 'views/home/home_screen.dart';
import 'views/startup_error_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await runZonedGuarded(() async {
    try {
      // R2 secrets live in .env for native builds only — never required on web.
      if (!kIsWeb) {
        await dotenv.load(fileName: '.env', isOptional: true);
      }

      await Firebase.initializeApp(
        options: resolveFirebaseOptions(),
      );

      // Required for Firebase Phone Auth reCAPTCHA on web (v2 + Enterprise).
      if (kIsWeb) {
        try {
          await FirebaseAuth.instance.initializeRecaptchaConfig();
        } catch (e) {
          if (kDebugMode) {
            debugPrint('initializeRecaptchaConfig failed: $e');
          }
        }
      }

      Locale initialLocale = AppLocaleConfig.defaultLocale;
      try {
        initialLocale = await loadSavedLocale();
      } catch (_) {
        // SharedPreferences can fail in some browsers; fall back to Kurdish.
      }
      setBootLocale(initialLocale);

      runApp(
        const ProviderScope(
          child: IQMotorsApp(),
        ),
      );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Startup failed: $error\n$stackTrace');
      }
      runApp(StartupErrorScreen(error: error, stackTrace: stackTrace));
    }
  }, (error, stackTrace) {
    if (kDebugMode) {
      debugPrint('Uncaught error: $error\n$stackTrace');
    }
  });
}

class IQMotorsApp extends ConsumerWidget {
  const IQMotorsApp({super.key});

  static final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'IQ Motors',
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: AppLocaleConfig.supportedLocales,
      localizationsDelegates: appLocalizationDelegates,
      localeResolutionCallback: (deviceLocale, supportedLocales) {
        return AppLocaleConfig.resolve(deviceLocale);
      },
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: analytics),
      ],
      builder: (context, child) {
        final direction = AppLocaleConfig.textDirectionFor(locale);
        return Directionality(
          textDirection: direction,
          child: child ?? const SizedBox.shrink(),
        );
      },
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F5F7),
        colorScheme: const ColorScheme.light(
          surface: Color(0xFFF5F5F7),
          onSurface: Color(0xFF1D1D1F),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
