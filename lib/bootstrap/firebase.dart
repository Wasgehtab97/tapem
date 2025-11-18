// lib/bootstrap/firebase.dart

import 'dart:async';
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';

import '../app_router.dart';
import '../firebase_options.dart';
import '../core/providers/functions_provider.dart';
import 'navigation.dart';

const bool kEnablePush = false;

Future<void> ensureFirebaseInitialized() async {
  try {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      await Firebase.initializeApp();
    } else {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
  }
}

Future<void> initializeAppCheck() async {
  await FirebaseAppCheck.instance.activate(
    appleProvider: AppleProvider.deviceCheck,
  );
}

void configureFirestorePersistence() {
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
}

void configurePhoneAuthForDebug() {
  assert(() {
    fb_auth.FirebaseAuth.instance.setSettings(
      appVerificationDisabledForTesting: true,
    );
    return true;
  }());
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await ensureFirebaseInitialized();
}

Future<void> initializePushMessaging() async {
  try {
    final messaging = FirebaseMessaging.instance;

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('[FCM] permission denied → skip');
        return;
      }
      final apns = await messaging.getAPNSToken();
      if (apns == null) {
        debugPrint('[FCM] no APNs token (simulator?) → skip FCM token fetch');
        return;
      }
    }

    final token = await messaging.getToken();
    if (token != null) {
      await _registerToken(token);
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      _registerToken(token)
          .catchError((error) => debugPrint('[FCM] onTokenRefresh error: $error'));
    });

    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  } catch (error, stackTrace) {
    debugPrint('[FCM] init failed: $error\n$stackTrace');
  }
}

Future<void> _registerToken(String token) async {
  final platform = defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
  try {
    await FunctionsProvider.instance.httpsCallable('registerPushToken').call({
      'token': token,
      'platform': platform,
    });
  } catch (error) {
    debugPrint('[FCM] registerPushToken failed: $error');
  }
}

void _handleMessage(RemoteMessage message) {
  final action = message.data['action'];
  if (action == 'open_requests') {
    navigatorKey.currentState?.pushNamed(AppRouter.friendsHome);
  } else if (action == 'open_friend') {
    final uid = message.data['uid'];
    navigatorKey.currentState?.pushNamed(
      AppRouter.friendDetail,
      arguments: uid,
    );
  }
}
