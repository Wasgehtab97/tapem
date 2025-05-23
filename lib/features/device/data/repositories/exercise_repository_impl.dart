// lib/features/device/data/repositories/exercise_repository_impl.dart
import '../sources/firestore_exercise_source.dart';
import '../../domain/models/exercise.dart';
import '../../domain/repositories/exercise_repository.dart';

class ExerciseRepositoryImpl implements ExerciseRepository {
  final FirestoreExerciseSource _src;
  ExerciseRepositoryImpl(this._src);

  @override
  Future<List<Exercise>> getExercises(String gymId, String deviceId) =>
      _src.getExercises(gymId, deviceId);

  @override
  Future<void> createExercise(String gymId, String deviceId, Exercise ex) =>
      _src.createExercise(gymId, deviceId, ex);

  @override
  Future<void> deleteExercise(String gymId, String deviceId, String exId) =>
      _src.deleteExercise(gymId, deviceId, exId);
}
