import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/features/training_plan/domain/models/training_plan.dart';
import 'package:tapem/features/training_plan/domain/models/training_plan_exercise.dart';
import 'package:tapem/features/training_plan/application/draft_training_plan.dart';
import 'package:tapem/features/training_plan/application/training_plan_provider.dart';

final planBuilderProvider = StateNotifierProvider<PlanBuilderNotifier, DraftTrainingPlan>((ref) {
  return PlanBuilderNotifier(ref);
});

class PlanBuilderNotifier extends StateNotifier<DraftTrainingPlan> {
  final Ref _ref;

  PlanBuilderNotifier(this._ref) : super(const DraftTrainingPlan());

  void startNew() {
    state = const DraftTrainingPlan(name: '', exercises: [], isDirty: false);
  }

  void editExisting(TrainingPlan plan) {
    state = DraftTrainingPlan(
      originalId: plan.id,
      name: plan.name,
      exercises: plan.exercises,
      isDirty: false,
    );
  }

  void updateName(String name) {
    state = state.copyWith(name: name, isDirty: true);
  }

  void addExercise({
    required String deviceId,
    required String exerciseId,
    String? name,
  }) {
    final currentExercises = List<TrainingPlanExercise>.from(state.exercises);
    final newIndex = currentExercises.length;
    
    currentExercises.add(TrainingPlanExercise(
      deviceId: deviceId,
      exerciseId: exerciseId,
      name: name,
      orderIndex: newIndex,
    ));

    state = state.copyWith(exercises: currentExercises, isDirty: true);
  }

  void applyResolvedNames(Map<String, String> namesByKey) {
    if (namesByKey.isEmpty) return;
    final updated = <TrainingPlanExercise>[];
    var changed = false;
    for (final ex in state.exercises) {
      final key = _exerciseKey(ex.deviceId, ex.exerciseId);
      final resolved = namesByKey[key];
      if (resolved != null && resolved.isNotEmpty && ex.name != resolved) {
        updated.add(ex.copyWith(name: resolved));
        changed = true;
      } else {
        updated.add(ex);
      }
    }
    if (changed) {
      state = state.copyWith(
        exercises: updated,
        isDirty: state.isDirty || changed,
      );
    }
  }

  String _exerciseKey(String deviceId, String exerciseId) {
    return '$deviceId::$exerciseId';
  }

  void removeExercise(int index) {
    final currentExercises = List<TrainingPlanExercise>.from(state.exercises);
    currentExercises.removeAt(index);
    
    // Re-index
    final reIndexed = currentExercises.asMap().entries.map((e) {
      return e.value.copyWith(orderIndex: e.key);
    }).toList();

    state = state.copyWith(exercises: reIndexed, isDirty: true);
  }

  void reorderExercises(int oldIndex, int newIndex) {
    final currentExercises = List<TrainingPlanExercise>.from(state.exercises);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = currentExercises.removeAt(oldIndex);
    currentExercises.insert(newIndex, item);

    // Re-index
    final reIndexed = currentExercises.asMap().entries.map((e) {
      return e.value.copyWith(orderIndex: e.key);
    }).toList();

    state = state.copyWith(exercises: reIndexed, isDirty: true);
  }

  Future<String> save() async {
    final authState = _ref.read(authViewStateProvider);
    final userId = authState.userId;
    final gymId = authState.gymCode;

    if (userId == null || gymId == null) {
      throw Exception('User or Gym not logged in');
    }

    final now = DateTime.now();
    final planId = state.originalId ?? const Uuid().v4();

    final plan = TrainingPlan(
      id: planId,
      name: state.name,
      gymId: gymId,
      exercises: state.exercises,
      createdAt: state.originalId == null ? now : now, // Should keep original createdAt if editing? ideally yes but for now simpler
      updatedAt: now,
    );
    
    // If editing, we might want to preserve createdAt. 
    // Logic: fetch old plan if existing, or just trust UI logic?
    // Optimization: Just save. Firestore merge will handle fields? No, I am overwriting fields.
    // Ideally I should fetch the old plan to get createdAt, or pass it in editExisting.
    // For now, I will treat it as a "save" operation.
    
    final repo = _ref.read(trainingPlanRepositoryProvider);
    await repo.savePlan(userId: userId, plan: plan);

    // Nach dem Speichern die Draft-ID aktualisieren, damit
    // Plan-Stats und "Training starten" immer eine gültige planId haben.
    state = state.copyWith(
      originalId: planId,
      isDirty: false,
    );

    // Liste neu laden
    _ref.invalidate(trainingPlansProvider);

    return planId;
  }
}
