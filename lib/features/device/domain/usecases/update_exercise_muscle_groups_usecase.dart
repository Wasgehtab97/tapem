import '../repositories/exercise_repository.dart';

class UpdateExerciseMuscleGroupsUseCase {
  final ExerciseRepository _repo;
  UpdateExerciseMuscleGroupsUseCase(this._repo);

  Future<void> execute(
    String gymId,
    String deviceId,
    String exerciseId,
    List<String> primaryGroups,
    List<String> secondaryGroups,
  ) =>
      _repo.updateMuscleGroups(
        gymId,
        deviceId,
        exerciseId,
        primaryGroups,
        secondaryGroups,
      );
}
