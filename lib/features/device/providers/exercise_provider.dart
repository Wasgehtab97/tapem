// lib/features/device/providers/exercise_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/providers/gym_scoped_resettable.dart';
import '../domain/models/exercise.dart';
import '../domain/services/exercise_xp_reassignment_service.dart';
import '../domain/usecases/create_exercise_usecase.dart';
import '../domain/usecases/delete_exercise_usecase.dart';
import '../domain/usecases/get_exercises_for_device.dart';
import '../domain/usecases/update_exercise_muscle_groups_usecase.dart';
import '../domain/usecases/update_exercise_usecase.dart';
import 'device_riverpod.dart';

class ExerciseProvider extends ChangeNotifier
    with GymScopedResettableChangeNotifier {
  final GetExercisesForDevice _getEx;
  final CreateExerciseUseCase _createEx;
  final DeleteExerciseUseCase _deleteEx;
  final UpdateExerciseUseCase _updateEx;
  final UpdateExerciseMuscleGroupsUseCase _updateMuscles;
  final ExerciseXpReassignmentService _xpReassignment;

  ExerciseProvider({
    required GetExercisesForDevice getEx,
    required CreateExerciseUseCase createEx,
    required DeleteExerciseUseCase deleteEx,
    required UpdateExerciseUseCase updateEx,
    required UpdateExerciseMuscleGroupsUseCase updateMuscles,
    ExerciseXpReassignmentService? xpReassignment,
  })  : _getEx = getEx,
        _createEx = createEx,
        _deleteEx = deleteEx,
        _updateEx = updateEx,
        _updateMuscles = updateMuscles,
        _xpReassignment = xpReassignment ?? ExerciseXpReassignmentService();

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
    } catch (e, st) {
      _error = e.toString();
      debugPrint('❌ [ExerciseProvider] loadExercises error: $e');
      debugPrintStack(stackTrace: st);
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

  Future<void> reassignMuscleXp(
    String gymId,
    String deviceId,
    String exerciseId,
    String userId,
    List<String> primaryIds,
    List<String> secondaryIds,
  ) {
    return _xpReassignment.reassign(
      gymId: gymId,
      deviceId: deviceId,
      exerciseId: exerciseId,
      userId: userId,
      newPrimaryIds: primaryIds,
      newSecondaryIds: secondaryIds,
    );
  }

  @override
  void resetGymScopedState() {
    _exercises = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    disposeGymScopedRegistration();
    super.dispose();
  }
}

final exerciseProvider = ChangeNotifierProvider<ExerciseProvider>((ref) {
  final provider = ExerciseProvider(
    getEx: ref.watch(getExercisesForDeviceProvider),
    createEx: ref.watch(createExerciseUseCaseProvider),
    deleteEx: ref.watch(deleteExerciseUseCaseProvider),
    updateEx: ref.watch(updateExerciseUseCaseProvider),
    updateMuscles: ref.watch(updateExerciseMuscleGroupsUseCaseProvider),
    xpReassignment: ref.watch(exerciseXpReassignmentServiceProvider),
  );
  final gymScopedController = ref.watch(gymScopedStateControllerProvider);
  provider.registerGymScopedResettable(gymScopedController);

  void handleAuthChange(AuthViewState? previous, AuthViewState next) {
    final gymChanged = previous?.gymCode != next.gymCode;
    final userChanged = previous?.userId != next.userId;
    if (!next.isLoggedIn || next.gymCode == null || next.userId == null) {
      provider.resetGymScopedState();
      return;
    }
    if (gymChanged || userChanged) {
      provider.resetGymScopedState();
    }
  }

  ref.listen<AuthViewState>(
    authViewStateProvider,
    handleAuthChange,
    fireImmediately: true,
  );

  ref.onDispose(provider.dispose);
  return provider;
});
