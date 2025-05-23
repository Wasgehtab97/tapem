// lib/features/device/domain/usecases/create_exercise_usecase.dart
import 'package:uuid/uuid.dart';
import '../models/exercise.dart';
import '../repositories/exercise_repository.dart';

class CreateExerciseUseCase {
  final ExerciseRepository _repo;
  final Uuid _uuid = const Uuid();
  CreateExerciseUseCase(this._repo);

  Future<void> execute(String gymId, String deviceId, String name, String userId) {
    final ex = Exercise(id: _uuid.v4(), name: name, userId: userId);
    return _repo.createExercise(gymId, deviceId, ex);
  }
}
