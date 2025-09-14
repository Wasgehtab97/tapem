// lib/features/history/domain/models/workout_log.dart

/// Domain-Modell eines Workout-Logs
class WorkoutLog {
  final String id;
  final String userId;
  final String sessionId;
  final String? exerciseId;
  final DateTime timestamp;
  final double? weight;
  final int? reps;
  final double? dropWeightKg;
  final int? dropReps;
  final int setNumber;
  final bool isBodyweight;

  // Cardio fields
  final bool isCardio;
  final String? mode;
  final int? durationSec;
  final double? speedKmH;
  final List<Map<String, dynamic>>? intervals;

  WorkoutLog({
    required this.id,
    required this.userId,
    required this.sessionId,
    this.exerciseId,
    required this.timestamp,
    this.weight,
    this.reps,
    this.dropWeightKg,
    this.dropReps,
    required this.setNumber,
    this.isBodyweight = false,
    this.isCardio = false,
    this.mode,
    this.durationSec,
    this.speedKmH,
    this.intervals,
  });
}
