// lib/features/device/data/repositories/exercise_repository_impl.dart
import '../sources/firestore_exercise_source.dart';
import '../../domain/models/exercise.dart';
import '../../domain/repositories/exercise_repository.dart';

class ExerciseRepositoryImpl implements ExerciseRepository {
  final FirestoreExerciseSource _src;
  ExerciseRepositoryImpl(this._src);

  @override
  Future<List<Exercise>> getExercises(
    String gymId,
    String deviceId,
    String userId,
  ) {
    return _src.getExercises(gymId, deviceId, userId);
  }

  @override
  Future<void> createExercise(String gymId, String deviceId, Exercise ex) {
    return _src.createExercise(gymId, deviceId, ex);
  }

  @override
  Future<void> updateExercise(String gymId, String deviceId, Exercise ex) {
    return _src.updateExercise(gymId, deviceId, ex);
  }

  @override
  Future<void> deleteExercise(
    String gymId,
    String deviceId,
    String exerciseId,
    String userId,
  ) {
    // Firestore Rules stellen sicher, dass only owner can delete
    return _src.deleteExercise(gymId, deviceId, exerciseId);
  }
}
