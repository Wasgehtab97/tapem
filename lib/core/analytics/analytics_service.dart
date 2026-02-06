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

  static Future<void> logGymSelected({
    required String gymId,
    String? source,
  }) {
    return logEvent(
      'gym_selected',
      parameters: {
        'gym_id': gymId,
        if (source != null && source.isNotEmpty) 'source': source,
      },
    );
  }

  static Future<void> logGymAuthChoice({
    required String gymId,
    required String action,
  }) {
    return logEvent(
      'gym_auth_choice',
      parameters: {
        'gym_id': gymId,
        'action': action,
      },
    );
  }

  static Future<void> logGymRegisterMethod({
    required String gymId,
    required String method,
  }) {
    return logEvent(
      'gym_register_method',
      parameters: {
        'gym_id': gymId,
        'method': method,
      },
    );
  }

  static Future<void> logGymNfcScan({
    required String gymId,
    required String flow,
    required String status,
    String? reason,
  }) {
    return logEvent(
      'gym_nfc_scan',
      parameters: {
        'gym_id': gymId,
        'flow': flow,
        'status': status,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
    );
  }

  static Future<void> logGymCodeValidation({
    required String gymId,
    required String status,
    String? reason,
  }) {
    return logEvent(
      'gym_code_validation',
      parameters: {
        'gym_id': gymId,
        'status': status,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
    );
  }

  static Future<void> logWorkoutNfcScan({
    required String userId,
    required String gymId,
    required String deviceId,
    required bool isMulti,
    required String status,
  }) {
    return logEvent(
      'workout_nfc_scan',
      parameters: {
        'user_id': userId,
        'gym_id': gymId,
        'device_id': deviceId,
        'is_multi': isMulti,
        'status': status, // success | failed
      },
    );
  }
}
