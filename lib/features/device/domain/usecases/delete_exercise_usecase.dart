// lib/features/device/domain/usecases/delete_exercise_usecase.dart
import '../repositories/exercise_repository.dart';

class DeleteExerciseUseCase {
  final ExerciseRepository _repo;
  DeleteExerciseUseCase(this._repo);

  Future<void> execute(
    String gymId,
    String deviceId,
    String exerciseId,
    String userId,
  ) {
    return _repo.deleteExercise(gymId, deviceId, exerciseId, userId);
  }
}
