// lib/features/device/domain/usecases/create_exercise_usecase.dart
import 'package:uuid/uuid.dart';
import '../models/exercise.dart';
import '../repositories/exercise_repository.dart';

class CreateExerciseUseCase {
  final ExerciseRepository _repo;
  final Uuid _uuid = const Uuid();
  CreateExerciseUseCase(this._repo);

  Future<Exercise> execute(
    String gymId,
    String deviceId,
    String name,
    String userId, {
    List<String>? muscleGroupIds,
  }) {
    final ex = Exercise(
      id: _uuid.v4(),
      name: name,
      userId: userId,
      muscleGroupIds: muscleGroupIds,
    );
    return _repo.createExercise(gymId, deviceId, ex).then((_) => ex);
  }
}
