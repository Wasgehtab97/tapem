import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/providers/gym_scoped_resettable.dart';
import 'package:tapem/core/providers/shared_preferences_provider.dart';
import 'package:tapem/features/device/providers/device_riverpod.dart';
import 'package:tapem/features/training_plan/data/repositories/training_plan_repository_impl.dart';
import 'package:tapem/features/training_plan/data/sources/firestore_training_plan_source.dart';
import 'package:tapem/features/training_plan/domain/models/exercise_entry.dart';
import 'package:tapem/features/training_plan/domain/models/split_day.dart';
import 'package:tapem/features/training_plan/domain/models/training_plan.dart';
import 'package:tapem/features/training_plan/domain/repositories/training_plan_repository.dart';

class TrainingPlanProvider extends ChangeNotifier
    with GymScopedResettableChangeNotifier {
  final TrainingPlanRepository _repo;
  final SharedPreferences _prefs;
  final Uuid _uuid = const Uuid();
  List<TrainingPlan> plans = [];
  TrainingPlan? currentPlan;
  String? activePlanId;
  bool isLoading = false;
  bool isSaving = false;
  String? error;

  TrainingPlanProvider({
    required SharedPreferences sharedPreferences,
    TrainingPlanRepository? repo,
  })  : _repo = repo ?? TrainingPlanRepositoryImpl(FirestoreTrainingPlanSource()),
        _prefs = sharedPreferences {
    _loadActivePlanId();
  }

  void _loadActivePlanId() {
    activePlanId = _prefs.getString('activePlanId');
    notifyListeners();
  }

  Future<void> setActivePlan(String id) async {
    activePlanId = id;
    await _prefs.setString('activePlanId', id);
    notifyListeners();
  }

  Future<void> loadPlans(String gymId, String userId) async {
    debugPrint('📥 TrainingPlanProvider.loadPlans gymId=$gymId userId=$userId');
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      plans = await _repo.getPlans(gymId, userId);
      debugPrint('ℹ️ Loaded ${plans.length} plans');
    } catch (e, st) {
      error = e.toString();
      debugPrintStack(label: 'loadPlans failed', stackTrace: st);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void createNewPlan(
    String name,
    String createdBy, {
    required int splitDays,
  }) {
    final normalizedSplitDays = splitDays < 1 ? 1 : splitDays;
    debugPrint(
      '➕ createNewPlan name=$name splitDays=$normalizedSplitDays',
    );

    currentPlan = TrainingPlan(
      id: _uuid.v4(),
      name: name,
      createdAt: DateTime.now(),
      createdBy: createdBy,
      days: [
        for (var i = 0; i < normalizedSplitDays; i++)
          SplitDay(index: i, exercises: []),
      ],
    );
    debugPrint('✅ Created plan ${currentPlan!.id}');
    notifyListeners();
  }

  void addExercise(int dayIndex, ExerciseEntry entry) {
    final plan = currentPlan;
    if (plan == null) return;
    if (dayIndex < 0 || dayIndex >= plan.days.length) return;
    final days = List<SplitDay>.from(plan.days);
    final day = days[dayIndex];
    days[dayIndex] = day.copyWith(
      exercises: [
        ...day.exercises,
        entry,
      ],
    );
    currentPlan = plan.copyWith(days: days);
    notifyListeners();
  }

  void updateExercise(int dayIndex, int index, ExerciseEntry entry) {
    final plan = currentPlan;
    if (plan == null) return;
    if (dayIndex < 0 || dayIndex >= plan.days.length) return;
    final day = plan.days[dayIndex];
    if (index < 0 || index >= day.exercises.length) return;
    final updatedExercises = List<ExerciseEntry>.from(day.exercises);
    updatedExercises[index] = entry;
    final days = List<SplitDay>.from(plan.days);
    days[dayIndex] = day.copyWith(exercises: updatedExercises);
    currentPlan = plan.copyWith(days: days);
    notifyListeners();
  }

  void removeExercise(int dayIndex, int index) {
    final plan = currentPlan;
    if (plan == null) return;
    if (dayIndex < 0 || dayIndex >= plan.days.length) return;
    final day = plan.days[dayIndex];
    if (index < 0 || index >= day.exercises.length) return;
    final updatedExercises = List<ExerciseEntry>.from(day.exercises)
      ..removeAt(index);
    final days = List<SplitDay>.from(plan.days);
    days[dayIndex] = day.copyWith(exercises: updatedExercises);
    currentPlan = plan.copyWith(days: days);
    notifyListeners();
  }

  void notify() => notifyListeners();

  ExerciseEntry? entryForDate(
    String deviceId,
    String exerciseId,
    DateTime date,
  ) {
    debugPrint(
      '🔎 entryForDate device=$deviceId exercise=$exerciseId date=$date',
    );
    if (activePlanId == null) return null;
    TrainingPlan? plan;
    try {
      plan = plans.firstWhere((p) => p.id == activePlanId);
    } catch (_) {
      plan = currentPlan;
    }
    if (plan == null) return null;
    for (final day in plan.days) {
      try {
        return day.exercises.firstWhere(
          (e) => e.deviceId == deviceId && e.exerciseId == exerciseId,
        );
      } catch (_) {}
    }
    return null;
  }

  Future<void> saveCurrentPlan(String gymId) async {
    if (currentPlan == null) return;
    debugPrint('💾 saveCurrentPlan plan=${currentPlan!.id} gymId=$gymId');
    isSaving = true;
    error = null;
    notifyListeners();
    try {
      await _repo.savePlan(gymId, currentPlan!);
      debugPrint('✅ Plan saved');
      plans = await _repo.getPlans(gymId, currentPlan!.createdBy);
    } catch (e) {
      error = 'Fehler beim Speichern: ' + e.toString();
      debugPrint('❌ saveCurrentPlan failed: $e');
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> renamePlan(String gymId, String planId, String newName) async {
    debugPrint('✏️ renamePlan id=$planId newName=$newName');
    await _repo.renamePlan(gymId, planId, newName);
    final idx = plans.indexWhere((p) => p.id == planId);
    if (idx >= 0) {
      plans[idx] = plans[idx].copyWith(name: newName);
    }
    notifyListeners();
  }

  Future<void> deletePlan(String gymId, String planId) async {
    debugPrint('🗑 deletePlan $planId');
    await _repo.deletePlan(gymId, planId);
    plans.removeWhere((p) => p.id == planId);
    if (activePlanId == planId) {
      activePlanId = null;
      await _prefs.remove('activePlanId');
    }
    notifyListeners();
  }

  @override
  void resetGymScopedState() {
    plans = [];
    currentPlan = null;
    isLoading = false;
    isSaving = false;
    error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    disposeGymScopedRegistration();
    super.dispose();
  }
}

final trainingPlanProvider = ChangeNotifierProvider<TrainingPlanProvider>((ref) {
  final provider = TrainingPlanProvider(
    sharedPreferences: ref.watch(sharedPreferencesProvider),
    repo: TrainingPlanRepositoryImpl(
      FirestoreTrainingPlanSource(
        firestore: ref.watch(firebaseFirestoreProvider),
      ),
    ),
  );
  final gymScopedController = ref.watch(gymScopedStateControllerProvider);
  provider.registerGymScopedResettable(gymScopedController);

  Future<void> handleAuth(AuthViewState state) async {
    final gymId = state.gymCode;
    final userId = state.userId;
    if (!state.isLoggedIn || gymId == null || userId == null) {
      provider.resetGymScopedState();
      return;
    }
    await provider.loadPlans(gymId, userId);
  }

  ref.listen<AuthViewState>(
    authViewStateProvider,
    (previous, next) {
      final gymChanged = previous?.gymCode != next.gymCode;
      final userChanged = previous?.userId != next.userId;
      if (!gymChanged && !userChanged) {
        if (!next.isLoggedIn || next.gymCode == null || next.userId == null) {
          provider.resetGymScopedState();
        }
        return;
      }
      unawaited(handleAuth(next));
    },
    fireImmediately: true,
  );

  ref.onDispose(provider.dispose);
  return provider;
});
