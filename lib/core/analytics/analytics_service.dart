import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  AnalyticsService._();

  static FirebaseAnalytics get _analytics => FirebaseAnalytics.instance;

  static Future<void> logEvent(
    String name, {
    Map<String, Object?> parameters = const {},
  }) async {
    if (kDebugMode) {
      // In Debug-Builds nur loggen, damit die Console nicht „zugemüllt“ wird.
      debugPrint('[Analytics] $name $parameters');
    }

    // FirebaseAnalytics erwartet Map<String, Object>; Null-Werte herausfiltern.
    final cleaned = <String, Object>{};
    parameters.forEach((key, value) {
      if (value != null) {
        cleaned[key] = value as Object;
      }
    });

    try {
      await _analytics.logEvent(
        name: name,
        parameters: cleaned,
      );
    } catch (e, st) {
      // Analytics darf nie die App crashen – bei fehlender Plattform-Integration
      // oder während der Entwicklung wird nur geloggt.
      if (kDebugMode) {
        debugPrint('[Analytics] Failed to log $name: $e');
        debugPrintStack(stackTrace: st);
      }
    }
  }

  static Future<void> logWorkoutStarted({
    required String gymId,
    required String userId,
  }) {
    return logEvent(
      'workout_started',
      parameters: {
        'gym_id': gymId,
        'user_id': userId,
      },
    );
  }

  static Future<void> logWorkoutCompleted({
    required String gymId,
    required String userId,
    required String sessionId,
    String? deviceId,
    String? exerciseId,
    int? durationMs,
    int? setCount,
  }) {
    return logEvent(
      'workout_completed',
      parameters: {
        'gym_id': gymId,
        'user_id': userId,
        'session_id': sessionId,
        if (deviceId != null && deviceId.isNotEmpty) 'device_id': deviceId,
        if (exerciseId != null && exerciseId.isNotEmpty) 'exercise_id': exerciseId,
        if (durationMs != null) 'duration_ms': durationMs,
        if (setCount != null) 'set_count': setCount,
      },
    );
  }

  static Future<void> logWorkoutDiscarded({
    required String gymId,
    required String userId,
    int? durationMs,
  }) {
    return logEvent(
      'workout_discarded',
      parameters: {
        'gym_id': gymId,
        'user_id': userId,
        if (durationMs != null) 'duration_ms': durationMs,
      },
    );
  }
}
