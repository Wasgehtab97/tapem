import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:tapem/bootstrap/navigation.dart';

/// Central handler for push notifications
class PushNotificationHandler {
  /// Handle notification received while app is in foreground
  static void handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification != null) {
      debugPrint('[Push] Foreground: ${notification.title}');
      debugPrint('[Push] Body: ${notification.body}');
      debugPrint('[Push] Data: ${message.data}');
      
      // Show in-app notification UI
      final context = navigatorKey.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${notification.title}: ${notification.body}'),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Handle notification tap when app was in background
  static void handleBackgroundTap(RemoteMessage message) {
    final action = message.data['action'] as String?;
    debugPrint('[Push] Background tap - Action: $action');
    debugPrint('[Push] Data: ${message.data}');
    
    // Navigation is handled in firebase.dart _handleMessage()
    // This is just for logging/analytics
  }

  /// Request notification permissions (iOS)
  static Future<void> requestPermissions() async {
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    
    debugPrint('[Push] Permission status: ${settings.authorizationStatus}');
    
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('[Push] User denied permissions');
    } else if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('[Push] User granted permissions');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('[Push] User granted provisional permissions');
    }
  }
}
