import 'package:cloud_firestore/cloud_firestore.dart';

class RestStatSummary {
  const RestStatSummary({
    required this.deviceId,
    required this.deviceName,
    required this.sampleCount,
    required this.sumActualRestMs,
    required this.sumPlannedRestMs,
    required this.plannedSampleCount,
    this.sumActualRestDurationMs = 0,
    this.sumSetCount = 0,
    this.exerciseId,
    this.exerciseName,
    this.lastSessionAt,
  });

  final String deviceId;
  final String deviceName;
  final String? exerciseId;
  final String? exerciseName;
  final int sampleCount;
  final double sumActualRestMs;
  final double sumPlannedRestMs;
  final int plannedSampleCount;
  final double sumActualRestDurationMs;
  final int sumSetCount;
  final DateTime? lastSessionAt;

  double? get averageActualRestMs =>
      sampleCount > 0 ? sumActualRestMs / sampleCount : null;

  double? get averagePlannedRestMs =>
      plannedSampleCount > 0 ? sumPlannedRestMs / plannedSampleCount : null;

  double get totalActualRestDurationMs {
    if (sumActualRestDurationMs > 0) {
      return sumActualRestDurationMs;
    }
    final average = averageActualRestMs;
    if (average != null && sumSetCount > 0) {
      return average * sumSetCount;
    }
    if (average != null && sampleCount > 0) {
      return average * sampleCount;
    }
    return sumActualRestMs;
  }

  double? get effectiveAverageActualRestMs {
    if (sumSetCount > 0) {
      final totalDuration = totalActualRestDurationMs;
      if (totalDuration > 0) {
        return totalDuration / sumSetCount;
      }
    }
    return averageActualRestMs;
  }

  RestStatSummary copyWith({
    String? deviceId,
    String? deviceName,
    String? exerciseId,
    String? exerciseName,
    int? sampleCount,
    double? sumActualRestMs,
    double? sumPlannedRestMs,
    int? plannedSampleCount,
    double? sumActualRestDurationMs,
    int? sumSetCount,
    DateTime? lastSessionAt,
  }) {
    return RestStatSummary(
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      sampleCount: sampleCount ?? this.sampleCount,
      sumActualRestMs: sumActualRestMs ?? this.sumActualRestMs,
      sumPlannedRestMs: sumPlannedRestMs ?? this.sumPlannedRestMs,
      plannedSampleCount: plannedSampleCount ?? this.plannedSampleCount,
      sumActualRestDurationMs:
          sumActualRestDurationMs ?? this.sumActualRestDurationMs,
      sumSetCount: sumSetCount ?? this.sumSetCount,
      lastSessionAt: lastSessionAt ?? this.lastSessionAt,
    );
  }

  factory RestStatSummary.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    final exerciseIdRaw = (data['exerciseId'] as String?) ?? '';
    final exerciseNameRaw = (data['exerciseName'] as String?) ?? '';
    final lastSession = data['lastSessionAt'];
    DateTime? lastSessionAt;
    if (lastSession is Timestamp) {
      lastSessionAt = lastSession.toDate();
    }
    return RestStatSummary(
      deviceId: (data['deviceId'] as String?) ?? doc.id,
      deviceName: (data['deviceName'] as String?) ??
          ((data['deviceId'] as String?) ?? doc.id),
      exerciseId: exerciseIdRaw.isEmpty ? null : exerciseIdRaw,
      exerciseName: exerciseNameRaw.isEmpty ? null : exerciseNameRaw,
      sampleCount: (data['sampleCount'] as num?)?.toInt() ?? 0,
      sumActualRestMs: (data['sumActualRestMs'] as num?)?.toDouble() ?? 0,
      sumPlannedRestMs: (data['sumPlannedRestMs'] as num?)?.toDouble() ?? 0,
      plannedSampleCount: (data['plannedSampleCount'] as num?)?.toInt() ?? 0,
      sumActualRestDurationMs:
          (data['sumActualRestDurationMs'] as num?)?.toDouble() ?? 0,
      sumSetCount: (data['sumSetCount'] as num?)?.toInt() ?? 0,
      lastSessionAt: lastSessionAt,
    );
  }

  factory RestStatSummary.fromJson(Map<String, dynamic> json) {
    final exerciseIdRaw = json['exerciseId'] as String?;
    final exerciseNameRaw = json['exerciseName'] as String?;
    final lastSessionRaw = json['lastSessionAt'] as String?;
    return RestStatSummary(
      deviceId: json['deviceId'] as String,
      deviceName: json['deviceName'] as String,
      exerciseId:
          exerciseIdRaw == null || exerciseIdRaw.isEmpty ? null : exerciseIdRaw,
      exerciseName: exerciseNameRaw == null || exerciseNameRaw.isEmpty
          ? null
          : exerciseNameRaw,
      sampleCount: (json['sampleCount'] as num?)?.toInt() ?? 0,
      sumActualRestMs: (json['sumActualRestMs'] as num?)?.toDouble() ?? 0,
      sumPlannedRestMs: (json['sumPlannedRestMs'] as num?)?.toDouble() ?? 0,
      plannedSampleCount: (json['plannedSampleCount'] as num?)?.toInt() ?? 0,
      sumActualRestDurationMs:
          (json['sumActualRestDurationMs'] as num?)?.toDouble() ?? 0,
      sumSetCount: (json['sumSetCount'] as num?)?.toInt() ?? 0,
      lastSessionAt:
          lastSessionRaw != null ? DateTime.tryParse(lastSessionRaw) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'deviceName': deviceName,
        'exerciseId': exerciseId ?? '',
        'exerciseName': exerciseName ?? '',
        'sampleCount': sampleCount,
        'sumActualRestMs': sumActualRestMs,
        'sumPlannedRestMs': sumPlannedRestMs,
        'plannedSampleCount': plannedSampleCount,
        'sumActualRestDurationMs': sumActualRestDurationMs,
        'sumSetCount': sumSetCount,
        if (lastSessionAt != null)
          'lastSessionAt': lastSessionAt!.toIso8601String(),
      };
}
