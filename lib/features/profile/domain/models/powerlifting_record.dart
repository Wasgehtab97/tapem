// lib/features/profile/domain/models/powerlifting_record.dart

import 'powerlifting_discipline.dart';

class PowerliftingRecord {
  const PowerliftingRecord({
    required this.id,
    required this.discipline,
    required this.weightKg,
    required this.reps,
    required this.performedAt,
    required this.deviceName,
    this.exerciseName,
  });

  final String id;
  final PowerliftingDiscipline discipline;
  final double weightKg;
  final int reps;
  final DateTime performedAt;
  final String deviceName;
  final String? exerciseName;
}
