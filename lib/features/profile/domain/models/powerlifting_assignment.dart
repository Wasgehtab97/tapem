// lib/features/profile/domain/models/powerlifting_assignment.dart

import 'powerlifting_discipline.dart';

/// Represents a user-configured source (device/exercise) that contributes to a
/// specific powerlifting discipline.
class PowerliftingAssignment {
  PowerliftingAssignment({
    required this.id,
    required this.discipline,
    required this.gymId,
    required this.deviceId,
    required this.exerciseId,
    required this.createdAt,
    this.latestRecords,
  });

  final String id;
  final PowerliftingDiscipline discipline;
  final String gymId;
  final String deviceId;
  final String exerciseId;
  final DateTime createdAt;
  final PowerliftingLatestRecords? latestRecords;

  String get sourceKey => '$gymId|$deviceId|$exerciseId';

  Map<String, dynamic> toMap() => {
        'discipline': discipline.id,
        'gymId': gymId,
        'deviceId': deviceId,
        'exerciseId': exerciseId,
        'createdAt': createdAt.toIso8601String(),
        if (latestRecords != null) 'latestRecords': latestRecords!.toMap(),
      };

  factory PowerliftingAssignment.fromMap(
    String id,
    Map<String, dynamic> data,
  ) {
    final discipline =
        PowerliftingDisciplineX.fromId(data['discipline'] as String?) ??
            PowerliftingDiscipline.benchPress;
    final createdRaw = data['createdAt'];
    DateTime createdAt;
    if (createdRaw is DateTime) {
      createdAt = createdRaw;
    } else if (createdRaw is String) {
      createdAt = DateTime.tryParse(createdRaw) ??
          DateTime.fromMillisecondsSinceEpoch(0);
    } else if (createdRaw is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(createdRaw);
    } else {
      createdAt = DateTime.fromMillisecondsSinceEpoch(0);
    }
    PowerliftingLatestRecords? latestRecords;
    final latestRaw = data['latestRecords'];
    if (latestRaw is Map<String, dynamic>) {
      latestRecords = PowerliftingLatestRecords.fromMap(latestRaw);
    }

    return PowerliftingAssignment(
      id: id,
      discipline: discipline,
      gymId: (data['gymId'] as String?)?.trim() ?? '',
      deviceId: (data['deviceId'] as String?)?.trim() ?? '',
      exerciseId: (data['exerciseId'] as String?)?.trim() ?? '',
      createdAt: createdAt,
      latestRecords: latestRecords,
    );
  }

  PowerliftingAssignment copyWith({
    String? id,
    PowerliftingDiscipline? discipline,
    String? gymId,
    String? deviceId,
    String? exerciseId,
    DateTime? createdAt,
    PowerliftingLatestRecords? latestRecords,
  }) {
    return PowerliftingAssignment(
      id: id ?? this.id,
      discipline: discipline ?? this.discipline,
      gymId: gymId ?? this.gymId,
      deviceId: deviceId ?? this.deviceId,
      exerciseId: exerciseId ?? this.exerciseId,
      createdAt: createdAt ?? this.createdAt,
      latestRecords: latestRecords ?? this.latestRecords,
    );
  }
}

/// Holds the aggregated best records for a single assignment. Populated by the
/// Cloud Function that maintains `users/{uid}/powerlifting_sources` so the
/// client can fetch top results with a single document read.
class PowerliftingLatestRecords {
  PowerliftingLatestRecords({
    this.heaviest = const <PowerliftingLogSnapshot>[],
    this.e1rm = const <PowerliftingLogSnapshot>[],
    this.updatedAt,
  });

  final List<PowerliftingLogSnapshot> heaviest;
  final List<PowerliftingLogSnapshot> e1rm;
  final DateTime? updatedAt;

  factory PowerliftingLatestRecords.fromMap(Map<String, dynamic> data) {
    final heaviestRaw = data['heaviest'];
    final e1rmRaw = data['e1rm'];
    final updatedRaw = data['updatedAt'];

    return PowerliftingLatestRecords(
      heaviest: _parseSnapshots(heaviestRaw),
      e1rm: _parseSnapshots(e1rmRaw),
      updatedAt: _parseDate(updatedRaw),
    );
  }

  Map<String, dynamic> toMap() => {
        'heaviest': heaviest.map((snapshot) => snapshot.toMap()).toList(),
        'e1rm': e1rm.map((snapshot) => snapshot.toMap()).toList(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };

  static List<PowerliftingLogSnapshot> _parseSnapshots(Object? raw) {
    if (raw is Iterable) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(PowerliftingLogSnapshot.fromMap)
          .toList();
    }
    return const <PowerliftingLogSnapshot>[];
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw is DateTime) {
      return raw;
    }
    if (raw is String) {
      return DateTime.tryParse(raw);
    }
    if (raw is int) {
      return DateTime.fromMillisecondsSinceEpoch(raw);
    }
    return null;
  }
}

/// Snapshot of a single log entry that has been pre-aggregated server-side.
class PowerliftingLogSnapshot {
  PowerliftingLogSnapshot({
    required this.logId,
    required this.weightKg,
    required this.reps,
    required this.performedAt,
    this.deviceId,
    this.exerciseId,
  });

  final String logId;
  final double weightKg;
  final int reps;
  final DateTime performedAt;
  final String? deviceId;
  final String? exerciseId;

  factory PowerliftingLogSnapshot.fromMap(Map<String, dynamic> data) {
    final rawId = (data['logId'] as String?) ?? (data['id'] as String?);
    final weight = (data['weightKg'] as num?) ?? (data['weight'] as num?) ?? 0;
    final reps = (data['reps'] as num?) ?? 0;
    final ts = data['timestamp'];

    return PowerliftingLogSnapshot(
      logId: rawId?.trim().isNotEmpty == true
          ? rawId!.trim()
          : _fallbackId(data),
      weightKg: weight.toDouble(),
      reps: reps.toInt(),
      performedAt: _parseTimestamp(ts),
      deviceId: (data['deviceId'] as String?)?.trim(),
      exerciseId: (data['exerciseId'] as String?)?.trim(),
    );
  }

  Map<String, dynamic> toMap() => {
        'logId': logId,
        'weightKg': weightKg,
        'reps': reps,
        'timestamp': performedAt.toIso8601String(),
        if (deviceId != null) 'deviceId': deviceId,
        if (exerciseId != null) 'exerciseId': exerciseId,
      };

  static DateTime _parseTimestamp(Object? raw) {
    if (raw is DateTime) {
      return raw;
    }
    if (raw is String) {
      return DateTime.tryParse(raw) ??
          DateTime.fromMillisecondsSinceEpoch(0);
    }
    if (raw is int) {
      return DateTime.fromMillisecondsSinceEpoch(raw);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static String _fallbackId(Map<String, dynamic> data) {
    final ts = data['timestamp'];
    final weight = (data['weightKg'] as num?) ?? (data['weight'] as num?) ?? 0;
    final reps = (data['reps'] as num?) ?? 0;
    int? millis;
    if (ts is int) {
      millis = ts;
    } else if (ts is String) {
      millis = DateTime.tryParse(ts)?.millisecondsSinceEpoch;
    } else if (ts is DateTime) {
      millis = ts.millisecondsSinceEpoch;
    }
    return 'agg:${millis ?? 0}:${weight.toDouble()}:${reps.toInt()}';
  }
}
