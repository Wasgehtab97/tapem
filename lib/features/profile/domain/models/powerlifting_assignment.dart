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
  });

  final String id;
  final PowerliftingDiscipline discipline;
  final String gymId;
  final String deviceId;
  final String exerciseId;
  final DateTime createdAt;

  String get sourceKey => '$gymId|$deviceId|$exerciseId';

  Map<String, dynamic> toMap() => {
        'discipline': discipline.id,
        'gymId': gymId,
        'deviceId': deviceId,
        'exerciseId': exerciseId,
        'createdAt': createdAt.toIso8601String(),
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
    return PowerliftingAssignment(
      id: id,
      discipline: discipline,
      gymId: (data['gymId'] as String?)?.trim() ?? '',
      deviceId: (data['deviceId'] as String?)?.trim() ?? '',
      exerciseId: (data['exerciseId'] as String?)?.trim() ?? '',
      createdAt: createdAt,
    );
  }

  PowerliftingAssignment copyWith({
    String? id,
    PowerliftingDiscipline? discipline,
    String? gymId,
    String? deviceId,
    String? exerciseId,
    DateTime? createdAt,
  }) {
    return PowerliftingAssignment(
      id: id ?? this.id,
      discipline: discipline ?? this.discipline,
      gymId: gymId ?? this.gymId,
      deviceId: deviceId ?? this.deviceId,
      exerciseId: exerciseId ?? this.exerciseId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
