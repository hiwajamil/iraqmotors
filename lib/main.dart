import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iq_motors/core/config/app_image_cache.dart';
import 'package:iq_motors/core/services/currency_service.dart';
import 'package:iq_motors/core/services/firebase_performance_service.dart';
import 'package:iq_motors/features/marketplace/data/services/car_notification_service.dart';

import 'package:iq_motors/core/localization/app_localization_delegates.dart';
import 'package:iq_motors/core/config/firebase_web_config.dart';
import 'package:iq_motors/core/localization/locale_config.dart';
import 'package:iq_motors/core/theme/app_theme.dart';
import 'package:iq_motors/app/providers/currency_provider.dart';
import 'package:iq_motors/app/providers/locale_provider.dart';
import 'package:iq_motors/app/providers/theme_provider.dart';
import 'package:iq_motors/app/screens/coming_soon_screen.dart';
import 'package:iq_motors/features/marketplace/presentation/screens/home_screen.dart';
import 'package:iq_motors/app/screens/startup_error_screen.dart';
import 'package:iq_motors/shared/widgets/pwa_install_banner.dart';

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
      AppImageCacheManager.configurePaintingCache();

      // Parallelize core startup configurations.
      await Future.wait([
        dotenv.load(fileName: '.env').catchError((_) {}),
        Firebase.initializeApp(options: resolveFirebaseOptions()),
      ]);

      // Enable Firestore offline persistence (client‑side cache) with 100MB bound.
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: 104857600,
      );

      // Concurrently load user settings (Locale + ThemeMode + CurrencyMode).
      Locale initialLocale = AppLocaleConfig.defaultLocale;
      ThemeMode initialThemeMode = ThemeMode.system;
      CurrencyMode initialCurrencyMode = CurrencyMode.usd;
      try {
        final results = await Future.wait([
          loadSavedLocale(),
          loadSavedThemeMode(),
          loadSavedCurrencyMode(),
        ]);
        initialLocale = results[0] as Locale;
        initialThemeMode = results[1] as ThemeMode;
        initialCurrencyMode = results[2] as CurrencyMode;
      } catch (_) {}

      setBootLocale(initialLocale);
      setBootThemeMode(initialThemeMode);
      setBootCurrencyMode(initialCurrencyMode);

      // Mount UI immediately for instant startup.
      runApp(
        const ProviderScope(
          child: IQMotorsApp(),
        ),
      );

      // Asynchronously initialize secondary background services without blocking startup.
      unawaited(_warmupBackgroundServices());
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

/// Non-blocking background initialization after UI frame render.
Future<void> _warmupBackgroundServices() async {
  // Performance Monitoring
  try {
    await FirebasePerformanceService.instance.setCollectionEnabled(!kDebugMode);
  } catch (_) {}

  // Firebase Cloud Messaging
  try {
    await CarNotificationService().init();
  } catch (e) {
    if (kDebugMode) debugPrint('FCM init failed: $e');
  }

  // reCAPTCHA Enterprise
  try {
    await FirebaseAuth.instance.initializeRecaptchaConfig();
  } catch (e) {
    if (kDebugMode) debugPrint('Recaptcha init failed: $e');
  }
}

class IQMotorsApp extends ConsumerWidget {
  const IQMotorsApp({super.key});

  static final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);

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
        final scheme = Theme.of(context).colorScheme;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final overlay = SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: scheme.surface,
          systemNavigationBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
        );
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlay,
          child: Directionality(
            textDirection: direction,
            child: PwaInstallHost(
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: isProductionWebDomain
          ? const ComingSoonScreen()
          : const HomeScreen(),
    );
  }
}
