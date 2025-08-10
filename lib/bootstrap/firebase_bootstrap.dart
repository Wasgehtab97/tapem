import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

class FirebaseBootstrap {
  final FirebaseApp app;
  final FirebaseFirestore firestore;
  final fb_auth.FirebaseAuth auth;
  final FirebaseRemoteConfig remoteConfig;
  final FirebaseFunctions? functions;

  FirebaseBootstrap({
    required this.app,
    required this.firestore,
    required this.auth,
    required this.remoteConfig,
    this.functions,
  });
}

Future<FirebaseBootstrap> firebaseBootstrap() async {
  FirebaseApp app;
  if (Firebase.apps.isNotEmpty) {
    if (kDebugMode) debugPrint('Using existing Firebase app');
    app = Firebase.app();
  } else {
    if (kDebugMode) debugPrint('Initializing Firebase app');
    app = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  assert(() {
    if (Firebase.apps.length != 1) {
      throw FlutterError('Expected exactly one Firebase app, found ${Firebase.apps.length}');
    }
    return true;
  }());

  final firestore = FirebaseFirestore.instanceFor(app: app);
  firestore.settings = const Settings(persistenceEnabled: true);

  final auth = fb_auth.FirebaseAuth.instanceFor(app: app);
  auth.setSettings(appVerificationDisabledForTesting: true);

  final remoteConfig = FirebaseRemoteConfig.instanceFor(app: app);

  FirebaseFunctions? functions;
  try {
    functions = FirebaseFunctions.instanceFor(app: app);
  } catch (_) {
    functions = null;
  }

  return FirebaseBootstrap(
    app: app,
    firestore: firestore,
    auth: auth,
    remoteConfig: remoteConfig,
    functions: functions,
  );
}
