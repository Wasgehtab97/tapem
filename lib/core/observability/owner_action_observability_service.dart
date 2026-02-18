import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

@immutable
class OwnerActionMetric {
  const OwnerActionMetric({
    required this.attempts,
    required this.successes,
    required this.failures,
    required this.permissionDenied,
    required this.avgLatencyMs,
    required this.lastLatencyMs,
    required this.updatedAt,
    this.lastErrorCode,
  });

  static const OwnerActionMetric initial = OwnerActionMetric(
    attempts: 0,
    successes: 0,
    failures: 0,
    permissionDenied: 0,
    avgLatencyMs: 0,
    lastLatencyMs: 0,
    updatedAt: null,
  );

  final int attempts;
  final int successes;
  final int failures;
  final int permissionDenied;
  final double avgLatencyMs;
  final double lastLatencyMs;
  final DateTime? updatedAt;
  final String? lastErrorCode;

  double get successRate => attempts == 0 ? 0 : successes / attempts;
  double get failedCommandRate => attempts == 0 ? 0 : failures / attempts;
  double get permissionDeniedRate =>
      attempts == 0 ? 0 : permissionDenied / attempts;

  OwnerActionMetric copyWith({
    int? attempts,
    int? successes,
    int? failures,
    int? permissionDenied,
    double? avgLatencyMs,
    double? lastLatencyMs,
    DateTime? updatedAt,
    String? lastErrorCode,
    bool clearLastErrorCode = false,
  }) {
    return OwnerActionMetric(
      attempts: attempts ?? this.attempts,
      successes: successes ?? this.successes,
      failures: failures ?? this.failures,
      permissionDenied: permissionDenied ?? this.permissionDenied,
      avgLatencyMs: avgLatencyMs ?? this.avgLatencyMs,
      lastLatencyMs: lastLatencyMs ?? this.lastLatencyMs,
      updatedAt: updatedAt ?? this.updatedAt,
      lastErrorCode: clearLastErrorCode
          ? null
          : (lastErrorCode ?? this.lastErrorCode),
    );
  }
}

@immutable
class OwnerActionMetricsSnapshot {
  const OwnerActionMetricsSnapshot({required this.actions});

  static const OwnerActionMetricsSnapshot initial = OwnerActionMetricsSnapshot(
    actions: <String, OwnerActionMetric>{},
  );

  final Map<String, OwnerActionMetric> actions;

  OwnerActionMetric metricFor(String action) {
    return actions[action] ?? OwnerActionMetric.initial;
  }

  int get totalAttempts =>
      actions.values.fold(0, (total, metric) => total + metric.attempts);

  int get totalSuccesses =>
      actions.values.fold(0, (total, metric) => total + metric.successes);

  int get totalFailures =>
      actions.values.fold(0, (total, metric) => total + metric.failures);

  int get totalPermissionDenied => actions.values.fold(
    0,
    (total, metric) => total + metric.permissionDenied,
  );

  double get successRate =>
      totalAttempts == 0 ? 0 : totalSuccesses / totalAttempts;
  double get failedCommandRate =>
      totalAttempts == 0 ? 0 : totalFailures / totalAttempts;
  double get permissionDeniedRate =>
      totalAttempts == 0 ? 0 : totalPermissionDenied / totalAttempts;
}

class OwnerActionObservabilityService {
  OwnerActionObservabilityService._();

  static final OwnerActionObservabilityService instance =
      OwnerActionObservabilityService._();

  final ValueNotifier<OwnerActionMetricsSnapshot> _metrics =
      ValueNotifier<OwnerActionMetricsSnapshot>(
        OwnerActionMetricsSnapshot.initial,
      );

  ValueListenable<OwnerActionMetricsSnapshot> get metricsListenable => _metrics;
  OwnerActionMetricsSnapshot get metrics => _metrics.value;

  Future<T> trackAction<T>({
    required String action,
    required Future<T> Function() command,
  }) async {
    final startedAt = DateTime.now();
    try {
      final result = await command();
      _record(action: action, startedAt: startedAt, succeeded: true);
      return result;
    } catch (error, stackTrace) {
      _record(
        action: action,
        startedAt: startedAt,
        succeeded: false,
        errorCode: _extractErrorCode(error),
        isPermissionDenied: _isPermissionDenied(error),
      );
      if (kDebugMode) {
        debugPrint(
          '[OwnerActionObservability] action=$action failed error=$error',
        );
        debugPrint('$stackTrace');
      }
      rethrow;
    }
  }

  @visibleForTesting
  void resetForTests() {
    _metrics.value = OwnerActionMetricsSnapshot.initial;
  }

  void _record({
    required String action,
    required DateTime startedAt,
    required bool succeeded,
    String? errorCode,
    bool isPermissionDenied = false,
  }) {
    final now = DateTime.now();
    final latencyMs = now.difference(startedAt).inMilliseconds.toDouble();
    final current = _metrics.value;
    final previousMetric = current.actions[action] ?? OwnerActionMetric.initial;
    final attempts = previousMetric.attempts + 1;
    final nextAverageLatencyMs =
        ((previousMetric.avgLatencyMs * previousMetric.attempts) + latencyMs) /
        attempts;

    final nextMetric = previousMetric.copyWith(
      attempts: attempts,
      successes: previousMetric.successes + (succeeded ? 1 : 0),
      failures: previousMetric.failures + (succeeded ? 0 : 1),
      permissionDenied:
          previousMetric.permissionDenied + (isPermissionDenied ? 1 : 0),
      avgLatencyMs: nextAverageLatencyMs,
      lastLatencyMs: latencyMs,
      updatedAt: now,
      lastErrorCode: errorCode,
      clearLastErrorCode: succeeded,
    );

    final updatedActions = <String, OwnerActionMetric>{
      ...current.actions,
      action: nextMetric,
    };
    _metrics.value = OwnerActionMetricsSnapshot(actions: updatedActions);
  }

  String? _extractErrorCode(Object error) {
    if (error is FirebaseException && error.code.isNotEmpty) {
      return error.code;
    }
    if (error is PlatformException && error.code.isNotEmpty) {
      return error.code;
    }
    return null;
  }

  bool _isPermissionDenied(Object error) {
    final code = _extractErrorCode(error);
    if (code == 'permission-denied') {
      return true;
    }
    final message = error.toString().toLowerCase();
    return message.contains('permission denied') ||
        message.contains('insufficient permissions');
  }
}
