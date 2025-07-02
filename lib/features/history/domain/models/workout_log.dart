// lib/features/history/domain/models/workout_log.dart

/// Domain-Modell eines Workout-Logs
class WorkoutLog {
  final String id;
  final String userId;
  final String sessionId;
  final DateTime timestamp;
  final double weight;
  final int reps;
  final int? rir;
  final String? note;

  WorkoutLog({
    required this.id,
    required this.userId,
    required this.sessionId,
    required this.timestamp,
    required this.weight,
    required this.reps,
    this.rir,
    this.note,
  });
}
