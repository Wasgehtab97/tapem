import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum OfflineFlowAlertKind { syncBacklog, deadLetterSpike }

@immutable
class OfflineFlowAlert {
  const OfflineFlowAlert({
    required this.kind,
    required this.message,
    required this.triggeredAt,
  });

  final OfflineFlowAlertKind kind;
  final String message;
  final DateTime triggeredAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'kind': kind.name,
      'message': message,
      'triggeredAt': triggeredAt.toIso8601String(),
    };
  }

  factory OfflineFlowAlert.fromJson(Map<String, dynamic> json) {
    final rawKind = (json['kind'] as String?)?.trim() ?? '';
    final kind = OfflineFlowAlertKind.values.firstWhere(
      (entry) => entry.name == rawKind,
      orElse: () => OfflineFlowAlertKind.syncBacklog,
    );
    return OfflineFlowAlert(
      kind: kind,
      message: (json['message'] as String?) ?? '',
      triggeredAt:
          DateTime.tryParse(json['triggeredAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

@immutable
class OfflineFlowMetricsSnapshot {
  const OfflineFlowMetricsSnapshot({
    required this.offlineStarts,
    required this.localSaveSuccesses,
    required this.queueLatencySamples,
    required this.avgQueueLatencyMs,
    required this.lastQueueLatencyMs,
    required this.deadLetterRate,
    required this.lastReconcileDurationMs,
    required this.pendingCount,
    required this.deadLetterCount,
    required this.updatedAt,
    this.activeAlert,
  });

  static const OfflineFlowMetricsSnapshot initial = OfflineFlowMetricsSnapshot(
    offlineStarts: 0,
    localSaveSuccesses: 0,
    queueLatencySamples: 0,
    avgQueueLatencyMs: 0,
    lastQueueLatencyMs: 0,
    deadLetterRate: 0,
    lastReconcileDurationMs: 0,
    pendingCount: 0,
    deadLetterCount: 0,
    updatedAt: null,
    activeAlert: null,
  );

  final int offlineStarts;
  final int localSaveSuccesses;
  final int queueLatencySamples;
  final double avgQueueLatencyMs;
  final double lastQueueLatencyMs;
  final double deadLetterRate;
  final int lastReconcileDurationMs;
  final int pendingCount;
  final int deadLetterCount;
  final DateTime? updatedAt;
  final OfflineFlowAlert? activeAlert;

  OfflineFlowMetricsSnapshot copyWith({
    int? offlineStarts,
    int? localSaveSuccesses,
    int? queueLatencySamples,
    double? avgQueueLatencyMs,
    double? lastQueueLatencyMs,
    double? deadLetterRate,
    int? lastReconcileDurationMs,
    int? pendingCount,
    int? deadLetterCount,
    DateTime? updatedAt,
    OfflineFlowAlert? activeAlert,
    bool clearAlert = false,
  }) {
    return OfflineFlowMetricsSnapshot(
      offlineStarts: offlineStarts ?? this.offlineStarts,
      localSaveSuccesses: localSaveSuccesses ?? this.localSaveSuccesses,
      queueLatencySamples: queueLatencySamples ?? this.queueLatencySamples,
      avgQueueLatencyMs: avgQueueLatencyMs ?? this.avgQueueLatencyMs,
      lastQueueLatencyMs: lastQueueLatencyMs ?? this.lastQueueLatencyMs,
      deadLetterRate: deadLetterRate ?? this.deadLetterRate,
      lastReconcileDurationMs:
          lastReconcileDurationMs ?? this.lastReconcileDurationMs,
      pendingCount: pendingCount ?? this.pendingCount,
      deadLetterCount: deadLetterCount ?? this.deadLetterCount,
      updatedAt: updatedAt ?? this.updatedAt,
      activeAlert: clearAlert ? null : (activeAlert ?? this.activeAlert),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'offlineStarts': offlineStarts,
      'localSaveSuccesses': localSaveSuccesses,
      'queueLatencySamples': queueLatencySamples,
      'avgQueueLatencyMs': avgQueueLatencyMs,
      'lastQueueLatencyMs': lastQueueLatencyMs,
      'deadLetterRate': deadLetterRate,
      'lastReconcileDurationMs': lastReconcileDurationMs,
      'pendingCount': pendingCount,
      'deadLetterCount': deadLetterCount,
      'updatedAt': updatedAt?.toIso8601String(),
      'activeAlert': activeAlert?.toJson(),
    };
  }

  factory OfflineFlowMetricsSnapshot.fromJson(Map<String, dynamic> json) {
    final rawAlert = json['activeAlert'];
    OfflineFlowAlert? activeAlert;
    if (rawAlert is Map<String, dynamic>) {
      activeAlert = OfflineFlowAlert.fromJson(rawAlert);
    } else if (rawAlert is Map) {
      activeAlert = OfflineFlowAlert.fromJson(
        rawAlert.map((key, value) => MapEntry('$key', value)),
      );
    }
    return OfflineFlowMetricsSnapshot(
      offlineStarts: (json['offlineStarts'] as num?)?.toInt() ?? 0,
      localSaveSuccesses: (json['localSaveSuccesses'] as num?)?.toInt() ?? 0,
      queueLatencySamples: (json['queueLatencySamples'] as num?)?.toInt() ?? 0,
      avgQueueLatencyMs: (json['avgQueueLatencyMs'] as num?)?.toDouble() ?? 0,
      lastQueueLatencyMs: (json['lastQueueLatencyMs'] as num?)?.toDouble() ?? 0,
      deadLetterRate: (json['deadLetterRate'] as num?)?.toDouble() ?? 0,
      lastReconcileDurationMs:
          (json['lastReconcileDurationMs'] as num?)?.toInt() ?? 0,
      pendingCount: (json['pendingCount'] as num?)?.toInt() ?? 0,
      deadLetterCount: (json['deadLetterCount'] as num?)?.toInt() ?? 0,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
      activeAlert: activeAlert,
    );
  }
}

class OfflineFlowObservabilityService {
  OfflineFlowObservabilityService._() {
    unawaited(_ensureHydrated());
  }

  static final OfflineFlowObservabilityService instance =
      OfflineFlowObservabilityService._();

  static const String _storageKey = 'offlineFlowMetrics/v1';
  static const int _syncBacklogAlertThreshold = 25;
  static const int _deadLetterSpikeAlertThreshold = 5;
  static const double _deadLetterRateAlertThreshold = 0.25;

  final ValueNotifier<OfflineFlowMetricsSnapshot> _metrics =
      ValueNotifier<OfflineFlowMetricsSnapshot>(
        OfflineFlowMetricsSnapshot.initial,
      );
  SharedPreferences? _prefs;
  bool _hydrated = false;

  ValueListenable<OfflineFlowMetricsSnapshot> get metricsListenable => _metrics;
  OfflineFlowMetricsSnapshot get metrics => _metrics.value;

  Future<void> recordOfflineStart() async {
    await _update((current, now) {
      return current.copyWith(
        offlineStarts: current.offlineStarts + 1,
        updatedAt: now,
      );
    });
  }

  Future<void> recordLocalSessionSaveSuccess() async {
    await _update((current, now) {
      return current.copyWith(
        localSaveSuccesses: current.localSaveSuccesses + 1,
        updatedAt: now,
      );
    });
  }

  Future<void> recordQueueSnapshot({
    required int pendingCount,
    required int deadLetterCount,
  }) async {
    await _update((current, now) {
      final deadLetterRate = _computeDeadLetterRate(
        pendingCount: pendingCount,
        deadLetterCount: deadLetterCount,
      );
      final alert = _resolveAlert(
        pendingCount: pendingCount,
        deadLetterCount: deadLetterCount,
        deadLetterRate: deadLetterRate,
        now: now,
      );
      return current.copyWith(
        pendingCount: pendingCount,
        deadLetterCount: deadLetterCount,
        deadLetterRate: deadLetterRate,
        updatedAt: now,
        activeAlert: alert,
        clearAlert: alert == null,
      );
    });
  }

  Future<void> recordSyncCycle({
    required int pendingCount,
    required int deadLetterCount,
    required int processedJobs,
    required Duration reconcileDuration,
    double? averageQueueLatencyMs,
  }) async {
    await _update((current, now) {
      final deadLetterRate = _computeDeadLetterRate(
        pendingCount: pendingCount,
        deadLetterCount: deadLetterCount,
      );
      var queueLatencySamples = current.queueLatencySamples;
      var avgQueueLatencyMs = current.avgQueueLatencyMs;
      var lastQueueLatencyMs = current.lastQueueLatencyMs;
      final latency = averageQueueLatencyMs;
      if (latency != null && latency > 0) {
        queueLatencySamples += 1;
        avgQueueLatencyMs =
            ((avgQueueLatencyMs * current.queueLatencySamples) + latency) /
            queueLatencySamples;
        lastQueueLatencyMs = latency;
      }
      final alert = _resolveAlert(
        pendingCount: pendingCount,
        deadLetterCount: deadLetterCount,
        deadLetterRate: deadLetterRate,
        now: now,
      );
      return current.copyWith(
        queueLatencySamples: queueLatencySamples,
        avgQueueLatencyMs: avgQueueLatencyMs,
        lastQueueLatencyMs: lastQueueLatencyMs,
        deadLetterRate: deadLetterRate,
        lastReconcileDurationMs: reconcileDuration.inMilliseconds,
        pendingCount: pendingCount,
        deadLetterCount: deadLetterCount,
        updatedAt: now,
        activeAlert: alert,
        clearAlert: alert == null,
      );
    });
    if (kDebugMode) {
      debugPrint(
        '[OfflineFlowObservability] sync_cycle processed=$processedJobs pending=$pendingCount deadLetter=$deadLetterCount',
      );
    }
  }

  @visibleForTesting
  Future<void> resetForTests() async {
    await _ensureHydrated();
    _metrics.value = OfflineFlowMetricsSnapshot.initial;
    final prefs = _prefs;
    if (prefs != null) {
      await prefs.remove(_storageKey);
    }
  }

  Future<void> _ensureHydrated() async {
    if (_hydrated) {
      return;
    }
    try {
      _prefs ??= await SharedPreferences.getInstance();
    } catch (_) {
      _hydrated = true;
      return;
    }
    final prefs = _prefs;
    if (prefs == null) {
      _hydrated = true;
      return;
    }
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          _metrics.value = OfflineFlowMetricsSnapshot.fromJson(decoded);
        }
      } catch (_) {
        await prefs.remove(_storageKey);
      }
    }
    _hydrated = true;
  }

  Future<void> _persist(OfflineFlowMetricsSnapshot snapshot) async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final prefs = _prefs;
      if (prefs == null) {
        return;
      }
      await prefs.setString(_storageKey, jsonEncode(snapshot.toJson()));
    } catch (_) {
      // Observability persistence is best-effort and must not fail call sites.
    }
  }

  Future<void> _update(
    OfflineFlowMetricsSnapshot Function(
      OfflineFlowMetricsSnapshot current,
      DateTime now,
    )
    mutate,
  ) async {
    await _ensureHydrated();
    final now = DateTime.now();
    final previous = _metrics.value;
    final next = mutate(previous, now);
    _metrics.value = next;
    await _persist(next);
    _logAlertTransition(previous.activeAlert, next.activeAlert);
  }

  double _computeDeadLetterRate({
    required int pendingCount,
    required int deadLetterCount,
  }) {
    final total = pendingCount + deadLetterCount;
    if (total <= 0) {
      return 0;
    }
    return deadLetterCount / total;
  }

  OfflineFlowAlert? _resolveAlert({
    required int pendingCount,
    required int deadLetterCount,
    required double deadLetterRate,
    required DateTime now,
  }) {
    if (pendingCount >= _syncBacklogAlertThreshold) {
      return OfflineFlowAlert(
        kind: OfflineFlowAlertKind.syncBacklog,
        message:
            'Sync-Stau erkannt: $pendingCount Jobs ausstehend (Schwelle $_syncBacklogAlertThreshold).',
        triggeredAt: now,
      );
    }
    if (deadLetterCount >= _deadLetterSpikeAlertThreshold ||
        deadLetterRate >= _deadLetterRateAlertThreshold) {
      final percent = (deadLetterRate * 100).toStringAsFixed(1);
      return OfflineFlowAlert(
        kind: OfflineFlowAlertKind.deadLetterSpike,
        message:
            'Dead-Letter-Spike: $deadLetterCount Jobs, Rate $percent% (Schwelle ${(_deadLetterRateAlertThreshold * 100).toStringAsFixed(0)}%).',
        triggeredAt: now,
      );
    }
    return null;
  }

  void _logAlertTransition(OfflineFlowAlert? previous, OfflineFlowAlert? next) {
    final previousKind = previous?.kind;
    final nextKind = next?.kind;
    if (previousKind == nextKind) {
      return;
    }
    if (next == null) {
      debugPrint('[OfflineFlowObservability] alert cleared');
      return;
    }
    debugPrint(
      '[OfflineFlowObservability] alert kind=${next.kind.name} message=${next.message}',
    );
  }
}
