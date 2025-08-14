// lib/core/providers/exercise_provider.dart
import 'package:flutter/foundation.dart';
import 'package:tapem/features/device/domain/models/exercise.dart';
import 'package:tapem/features/device/domain/usecases/get_exercises_for_device.dart';
import 'package:tapem/features/device/domain/usecases/create_exercise_usecase.dart';
import 'package:tapem/features/device/domain/usecases/delete_exercise_usecase.dart';
import 'package:tapem/features/device/domain/usecases/update_exercise_usecase.dart';
import 'package:tapem/features/device/domain/usecases/update_exercise_muscle_groups_usecase.dart';

class ExerciseProvider extends ChangeNotifier {
  final GetExercisesForDevice _getEx;
  final CreateExerciseUseCase _createEx;
  final DeleteExerciseUseCase _deleteEx;
  final UpdateExerciseUseCase _updateEx;
  final UpdateExerciseMuscleGroupsUseCase _updateMuscles;

  ExerciseProvider({
    required GetExercisesForDevice getEx,
    required CreateExerciseUseCase createEx,
    required DeleteExerciseUseCase deleteEx,
    required UpdateExerciseUseCase updateEx,
    required UpdateExerciseMuscleGroupsUseCase updateMuscles,
  }) : _getEx = getEx,
       _createEx = createEx,
       _deleteEx = deleteEx,
       _updateEx = updateEx,
       _updateMuscles = updateMuscles;

  List<Exercise> _exercises = [];
  bool _isLoading = false;
  String? _error;

  List<Exercise> get exercises => List.unmodifiable(_exercises);
  bool get isLoading => _isLoading;
  String? get error => _error;

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
    String userId, {
    List<String>? primaryMuscleGroupIds,
    List<String>? secondaryMuscleGroupIds,
  }) async {
    final ex = await _createEx.execute(
      gymId,
      deviceId,
      name,
      userId,
      primaryMuscleGroupIds: primaryMuscleGroupIds,
      secondaryMuscleGroupIds: secondaryMuscleGroupIds,
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

  Future<void> updateExercise(
    String gymId,
    String deviceId,
    String exerciseId,
    String name,
    String userId, {
    List<String>? primaryMuscleGroupIds,
    List<String>? secondaryMuscleGroupIds,
  }) async {
    final ex = Exercise(
      id: exerciseId,
      name: name,
      userId: userId,
      primaryMuscleGroupIds: primaryMuscleGroupIds ?? const [],
      secondaryMuscleGroupIds: secondaryMuscleGroupIds ?? const [],
    );
    await _updateEx.execute(gymId, deviceId, ex);
    await loadExercises(gymId, deviceId, userId);
  }

  Future<void> updateMuscleGroups(
    String gymId,
    String deviceId,
    String exerciseId,
    String userId,
    List<String> primaryIds,
    List<String> secondaryIds,
  ) async {
    await _updateMuscles.execute(
      gymId,
      deviceId,
      exerciseId,
      primaryIds,
      secondaryIds,
    );
    final idx = _exercises.indexWhere((e) => e.id == exerciseId);
    if (idx != -1) {
      _exercises[idx] = _exercises[idx].copyWith(
        primaryMuscleGroupIds: primaryIds,
        secondaryMuscleGroupIds: secondaryIds,
      );
      notifyListeners();
    } else {
      await loadExercises(gymId, deviceId, userId);
    }
  }
}
