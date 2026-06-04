import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase configuration for IQ Motors (`iqmotors-d588d`).
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
        return web;
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        throw UnsupportedError(
          'Run `flutterfire configure` after registering this platform in '
          'the Firebase console.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBYX6e-32IsAo28XPhBPlZGlRjS01cUSHA',
    appId: '1:426861136448:web:8177bb2fffed65c74c2da5',
    messagingSenderId: '426861136448',
    projectId: 'iqmotors-d588d',
    authDomain: 'iqmotors-d588d.firebaseapp.com',
    storageBucket: 'iqmotors-d588d.firebasestorage.app',
    measurementId: 'G-BCGJYXYT2R',
  );
}
