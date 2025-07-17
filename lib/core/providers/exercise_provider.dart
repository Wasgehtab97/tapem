// lib/core/providers/exercise_provider.dart
import 'package:flutter/foundation.dart';
import 'package:tapem/features/device/domain/models/exercise.dart';
import 'package:tapem/features/device/domain/usecases/get_exercises_for_device.dart';
import 'package:tapem/features/device/domain/usecases/create_exercise_usecase.dart';
import 'package:tapem/features/device/domain/usecases/delete_exercise_usecase.dart';

class ExerciseProvider extends ChangeNotifier {
  final GetExercisesForDevice _getEx;
  final CreateExerciseUseCase _createEx;
  final DeleteExerciseUseCase _deleteEx;

  ExerciseProvider({
    required GetExercisesForDevice getEx,
    required CreateExerciseUseCase createEx,
    required DeleteExerciseUseCase deleteEx,
  })  : _getEx = getEx,
        _createEx = createEx,
        _deleteEx = deleteEx;

  List<Exercise> _exercises = [];
  bool _isLoading = false;
  String? _error;

  List<Exercise> get exercises => List.unmodifiable(_exercises);
  bool get isLoading    => _isLoading;
  String? get error     => _error;

  Future<void> loadExercises(
    String gymId,
    String deviceId,
    String userId,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _exercises = await _getEx.execute(gymId, deviceId, userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Exercise> addExercise(
    String gymId,
    String deviceId,
    String name,
    String userId,
    {List<String>? muscleGroupIds},
  ) async {
    final ex = await _createEx.execute(
      gymId,
      deviceId,
      name,
      userId,
      muscleGroupIds: muscleGroupIds,
    );
    await loadExercises(gymId, deviceId, userId);
    return ex;
  }

  Future<void> removeExercise(
    String gymId,
    String deviceId,
    String exerciseId,
    String userId,
  ) async {
    await _deleteEx.execute(gymId, deviceId, exerciseId, userId);
    await loadExercises(gymId, deviceId, userId);
  }
}
