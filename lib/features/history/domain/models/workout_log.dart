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
  final List<DropSet> dropSets;

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
    this.dropSets = const [],
  });
}

class DropSet {
  final double weightKg;
  final int reps;

  DropSet({required this.weightKg, required this.reps});
}
