// lib/features/device/domain/repositories/exercise_repository.dart
import '../models/exercise.dart';

abstract class ExerciseRepository {
  Future<List<Exercise>> getExercises(
    String gymId,
    String deviceId,
    String userId,
  );
  Future<void> createExercise(String gymId, String deviceId, Exercise ex);
  Future<void> deleteExercise(
    String gymId,
    String deviceId,
    String exerciseId,
    String userId,
  );
}
