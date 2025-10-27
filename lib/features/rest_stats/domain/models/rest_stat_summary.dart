import 'package:cloud_firestore/cloud_firestore.dart';

class RestStatSummary {
  const RestStatSummary({
    required this.deviceId,
    required this.deviceName,
    required this.sampleCount,
    required this.sumActualRestMs,
    required this.sumPlannedRestMs,
    required this.plannedSampleCount,
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
  final DateTime? lastSessionAt;

  double? get averageActualRestMs =>
      sampleCount > 0 ? sumActualRestMs / sampleCount : null;

  double? get averagePlannedRestMs =>
      plannedSampleCount > 0 ? sumPlannedRestMs / plannedSampleCount : null;

  RestStatSummary copyWith({
    String? deviceId,
    String? deviceName,
    String? exerciseId,
    String? exerciseName,
    int? sampleCount,
    double? sumActualRestMs,
    double? sumPlannedRestMs,
    int? plannedSampleCount,
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
        if (lastSessionAt != null)
          'lastSessionAt': lastSessionAt!.toIso8601String(),
      };
}
