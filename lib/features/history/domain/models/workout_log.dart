// lib/features/history/domain/models/workout_log.dart

/// Domain-Modell eines Workout-Logs
class WorkoutLog {
  final String id;
  final String userId;
  final String sessionId;
  final String? exerciseId;
  final DateTime timestamp;
  final double weight;
  final int reps;
  final int? rir;
  final String? note;
  final double? dropWeightKg;
  final int? dropReps;
  final int setNumber;

  WorkoutLog({
    required this.id,
    required this.userId,
    required this.sessionId,
    this.exerciseId,
    required this.timestamp,
    required this.weight,
    required this.reps,
    this.rir,
    this.note,
    this.dropWeightKg,
    this.dropReps,
    required this.setNumber,
  });
}
