// lib/features/device/domain/usecases/get_exercises_for_device.dart
import '../models/exercise.dart';
import '../repositories/exercise_repository.dart';

class GetExercisesForDevice {
  final ExerciseRepository _repo;
  GetExercisesForDevice(this._repo);

  Future<List<Exercise>> execute(String gymId, String deviceId) =>
    _repo.getExercises(gymId, deviceId);
}
