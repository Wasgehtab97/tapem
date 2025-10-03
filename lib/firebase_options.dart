import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions are not configured for web. '
        'Provide web Firebase configuration before targeting that platform.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform. '
          'Android and other native platforms should use their bundled Firebase config files.',
        );
    }
  }

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAx1f8Y6CaRoWBEfmAJzdIIALd0Hfg6x9c',
    appId: '1:380604353667:ios:6911c23daf736928229fb6',
    messagingSenderId: '380604353667',
    projectId: 'tap-em',
    iosBundleId: 'com.tapem.app',
    storageBucket: 'tap-em.firebasestorage.app',
  );
}

