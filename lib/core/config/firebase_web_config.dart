import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'package:iq_motors/firebase_options.dart';

/// Custom domains served from Firebase Hosting for this project.
const productionWebHosts = {
  'iqmotors.net',
  'www.iqmotors.net',
  'iqmotors-d588d.web.app',
  'iqmotors-d588d.firebaseapp.com',
};

/// Firebase [authDomain] stays on the default `*.firebaseapp.com` host for every
/// web origin. Each site origin (`iqmotors.net`, `*.web.app`, …) must be listed
/// under Authentication → Settings → Authorized domains instead.
String resolveFirebaseAuthDomain() {
  const fallback = 'iqmotors-d588d.firebaseapp.com';
  return DefaultFirebaseOptions.web.authDomain ?? fallback;
}

FirebaseOptions resolveFirebaseOptions() {
  final platform = DefaultFirebaseOptions.currentPlatform;
  if (!kIsWeb) return platform;

  final authDomain = resolveFirebaseAuthDomain();
  if (authDomain == platform.authDomain) return platform;

  return FirebaseOptions(
    apiKey: platform.apiKey,
    appId: platform.appId,
    messagingSenderId: platform.messagingSenderId,
    projectId: platform.projectId,
    authDomain: authDomain,
    storageBucket: platform.storageBucket,
    measurementId: platform.measurementId,
  );
}
