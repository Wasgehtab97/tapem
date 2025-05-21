// lib/features/history/domain/models/workout_log.dart

/// Domain-Modell eines Workout-Logs
class WorkoutLog {
  final String id;
  final String userId;
  final String sessionId;
  final DateTime timestamp;
  final int weight;
  final int reps;

  WorkoutLog({
    required this.id,
    required this.userId,
    required this.sessionId,
    required this.timestamp,
    required this.weight,
    required this.reps,
  });
}
