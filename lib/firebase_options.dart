import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options_dev.dart' as dev;
import 'firebase_options_prod.dart' as prod;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    final env = dotenv.get('ENVIRONMENT', fallback: 'dev');

    switch (env) {
      case 'prod':
        return prod.DefaultFirebaseOptions.currentPlatform;
      default:
        return dev.DefaultFirebaseOptions.currentPlatform;
    }
  }
}
