import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return ios;
  }

  static FirebaseOptions ios = const FirebaseOptions(
    apiKey: 'AIzaSyAx1f8Y6CaRoWBEfmAJzdIIALd0Hfg6x9c',
    appId: '1:380604353667:ios:6911c23daf736928229fb6',
    messagingSenderId: '380604353667',
    projectId: 'tap-em',
  );
}

