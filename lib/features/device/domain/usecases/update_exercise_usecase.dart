import '../models/exercise.dart';
import '../repositories/exercise_repository.dart';

class UpdateExerciseUseCase {
  final ExerciseRepository _repo;
  UpdateExerciseUseCase(this._repo);

  Future<void> execute(String gymId, String deviceId, Exercise ex) {
    return _repo.updateExercise(gymId, deviceId, ex);
  }
}
