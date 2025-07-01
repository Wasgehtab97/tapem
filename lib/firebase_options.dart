// lib/firebase_options.dart

// **************************************************************************
// ** Diese Datei wurde manuell erstellt/optimiert aus deiner GoogleService-Info.plist. **
// ** Sie enthält die iOS-Konfiguration komplett. Die Android/Web-Werte    **
// ** sind Platzhalter und nur nötig, wenn du Android/Web nutzt.          **
// **************************************************************************

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  /// Liefert je nach Plattform die passenden Optionen aus.
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  //────────────────────────────────────────────────────────────────────────────
  // Web-Konfiguration (nur relevant, wenn du Web targetest):
  // Ersetze <WEB_APP_ID> / <MEASUREMENT_ID> beim Bedarf.
  //────────────────────────────────────────────────────────────────────────────
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAx1f8Y6CaRoWBEfmAJzdIIALd0Hfg6x9c',
    authDomain: 'tap-em.firebaseapp.com',
    projectId: 'tap-em',
    storageBucket: 'tap-em.firebasestorage.app',
    messagingSenderId: '380604353667',
    appId: '1:380604353667:web:<WEB_APP_ID>',
    measurementId: '<MEASUREMENT_ID>',
  );

  //────────────────────────────────────────────────────────────────────────────
  // Android-Konfiguration (lediglich Platzhalter, falls du Android baust):
  // Ersetze <ANDROID_APP_ID> mit dem echten Wert aus google-services.json.
  //────────────────────────────────────────────────────────────────────────────
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAx1f8Y6CaRoWBEfmAJzdIIALd0Hfg6x9c',
    appId: '1:380604353667:android:<ANDROID_APP_ID>',
    messagingSenderId: '380604353667',
    projectId: 'tap-em',
    storageBucket: 'tap-em.firebasestorage.app',
  );

  //────────────────────────────────────────────────────────────────────────────
  // iOS-Konfiguration (aus deiner GoogleService-Info.plist):
  //────────────────────────────────────────────────────────────────────────────
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAx1f8Y6CaRoWBEfmAJzdIIALd0Hfg6x9c',
    appId: '1:380604353667:ios:6911c23daf736928229fb6',
    messagingSenderId: '380604353667',
    projectId: 'tap-em',
    storageBucket: 'tap-em.firebasestorage.app',
    iosBundleId: 'com.example.tapem',
    // iosClientId weglassen, weil hier nicht zwingend nötig (kein Google-SignIn).
  );

  //────────────────────────────────────────────────────────────────────────────
  // macOS-Konfiguration (falls du macOS später unterstützen willst, hier ausfüllen):
  // Ersetze <MACOS_APP_ID> / <IOS_CLIENT_ID> beim Bedarf.
  //────────────────────────────────────────────────────────────────────────────
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAx1f8Y6CaRoWBEfmAJzdIIALd0Hfg6x9c',
    appId: '1:380604353667:macos:<MACOS_APP_ID>',
    messagingSenderId: '380604353667',
    projectId: 'tap-em',
    storageBucket: 'tap-em.firebasestorage.app',
    iosBundleId: 'com.example.tapem',
  );
}
