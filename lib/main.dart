import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iq_motors/core/localization/app_localization_delegates.dart';
import 'package:iq_motors/core/config/firebase_web_config.dart';
import 'package:iq_motors/core/localization/locale_config.dart';
import 'package:iq_motors/core/config/recaptcha_enterprise_config.dart';
import 'package:iq_motors/app/providers/locale_provider.dart';
import 'package:iq_motors/app/screens/coming_soon_screen.dart';
import 'package:iq_motors/features/marketplace/presentation/screens/home_screen.dart';
import 'package:iq_motors/app/screens/startup_error_screen.dart';

/// True on web when the app is served from the public production domain.
bool get isProductionWebDomain {
  if (!kIsWeb) return false;
  final host = Uri.base.host;
  return host == 'iqmotors.net' || host == 'www.iqmotors.net';
}

Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      // R2 + Gemini keys from bundled `.env` (must be listed in pubspec assets).
      await dotenv.load(fileName: '.env');
      if (kDebugMode) {
        final hasR2Keys =
            (dotenv.env['R2_ACCESS_KEY_ID']?.trim().isNotEmpty ?? false) &&
                (dotenv.env['R2_SECRET_ACCESS_KEY']?.trim().isNotEmpty ??
                    false);
        if (!hasR2Keys) {
          debugPrint(
            'R2 credentials not loaded from .env. Copy .env.example to .env '
            'in the project root, or set keys in Admin → Security.',
          );
        }
      }

      await Firebase.initializeApp(
        options: resolveFirebaseOptions(),
      );

      // reCAPTCHA Enterprise (web, Android, iOS) — required before phone OTP.
      try {
        await FirebaseAuth.instance.initializeRecaptchaConfig();
        if (kDebugMode) {
          debugPrint(
            'reCAPTCHA Enterprise initialized '
            '(web=${RecaptchaEnterpriseConfig.webSiteKey.substring(0, 8)}…)',
          );
        }
      } catch (e, stackTrace) {
        debugPrint('initializeRecaptchaConfig failed: $e\n$stackTrace');
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
      home: isProductionWebDomain
          ? const ComingSoonScreen()
          : const HomeScreen(),
    );
  }
}
