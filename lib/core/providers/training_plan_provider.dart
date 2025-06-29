import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:tapem/features/training_plan/data/repositories/training_plan_repository_impl.dart';
import 'package:tapem/features/training_plan/data/sources/firestore_training_plan_source.dart';
import 'package:tapem/features/training_plan/domain/models/exercise_entry.dart';
import 'package:tapem/features/training_plan/domain/models/training_plan.dart';
import 'package:tapem/features/training_plan/domain/models/week_block.dart';
import 'package:tapem/features/training_plan/domain/models/day_entry.dart';
import 'package:tapem/features/training_plan/domain/repositories/training_plan_repository.dart';

class TrainingPlanProvider extends ChangeNotifier {
  final TrainingPlanRepository _repo;
  final Uuid _uuid = const Uuid();

  List<TrainingPlan> plans = [];
  TrainingPlan? currentPlan;
  String? activePlanId;
  bool isLoading = false;
  bool isSaving = false;
  String? error;

  TrainingPlanProvider({TrainingPlanRepository? repo})
    : _repo = repo ?? TrainingPlanRepositoryImpl(FirestoreTrainingPlanSource()) {
    _loadActivePlanId();
  }

  Future<void> _loadActivePlanId() async {
    final prefs = await SharedPreferences.getInstance();
    activePlanId = prefs.getString('activePlanId');
  }

  Future<void> setActivePlan(String id) async {
    activePlanId = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('activePlanId', id);
    notifyListeners();
  }

  Future<void> loadPlans(String gymId, String userId) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      plans = await _repo.getPlans(gymId, userId);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void createNewPlan(
    String name,
    String createdBy, {
    required int weeks,
  }) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekBlocks = [
      for (var i = 0; i < weeks; i++)
        WeekBlock(
          weekNumber: i + 1,
          days: [
            for (var d = 0; d < 7; d++)
              DayEntry(
                date: monday.add(Duration(days: i * 7 + d)),
                exercises: [],
              )
          ],
        )
    ];

    currentPlan = TrainingPlan(
      id: _uuid.v4(),
      name: name,
      createdAt: DateTime.now(),
      createdBy: createdBy,
      startDate: DateTime.now(),
      weeks: weekBlocks,
    );
    notifyListeners();
  }

  void addDay(int week, DateTime date) {
    final w = currentPlan?.weeks.firstWhere((e) => e.weekNumber == week);
    if (w == null) return;
    final exists = w.days.any((d) =>
        d.date.year == date.year && d.date.month == date.month && d.date.day == date.day);
    if (exists) return;
    w.days.add(DayEntry(date: date, exercises: []));
    w.days.sort((a, b) => a.date.compareTo(b.date));
    notifyListeners();
  }

  void removeDay(int week, DateTime date) {
    final w = currentPlan?.weeks.firstWhere((e) => e.weekNumber == week);
    if (w == null) return;
    w.days.removeWhere((d) =>
        d.date.year == date.year && d.date.month == date.month && d.date.day == date.day);
    notifyListeners();
  }

  void addExercise(int week, DateTime day, ExerciseEntry entry) {
    final w = currentPlan?.weeks.firstWhere((e) => e.weekNumber == week);
    if (w == null) return;
    final d = w.days.firstWhere((e) => e.date == day);
    d.exercises.add(entry);
    notifyListeners();
  }

  void updateExercise(int week, DateTime day, int index, ExerciseEntry entry) {
    final w = currentPlan?.weeks.firstWhere((e) => e.weekNumber == week);
    if (w == null) return;
    final d = w.days.firstWhere((e) => e.date == day);
    if (index < 0 || index >= d.exercises.length) return;
    d.exercises[index] = entry;
    notifyListeners();
  }

  void removeExercise(int week, DateTime day, int index) {
    final w = currentPlan?.weeks.firstWhere((e) => e.weekNumber == week);
    if (w == null) return;
    final d = w.days.firstWhere((e) => e.date == day);
    if (index < 0 || index >= d.exercises.length) return;
    d.exercises.removeAt(index);
    notifyListeners();
  }

  void notify() => notifyListeners();

  ExerciseEntry? entryForDate(
    String deviceId,
    String exerciseId,
    DateTime date,
  ) {
    if (activePlanId == null) return null;
    TrainingPlan? plan;
    try {
      plan = plans.firstWhere((p) => p.id == activePlanId);
    } catch (_) {
      plan = currentPlan;
    }
    if (plan == null) return null;
    for (final week in plan.weeks) {
      for (final day in week.days) {
        final d = DateTime(day.date.year, day.date.month, day.date.day);
        final target = DateTime(date.year, date.month, date.day);
        if (d == target) {
          try {
            return day.exercises.firstWhere(
              (e) => e.deviceId == deviceId && e.exerciseId == exerciseId,
            );
          } catch (_) {}
        }
      }
    }
    return null;
  }

  Future<void> saveCurrentPlan(String gymId) async {
    if (currentPlan == null) return;
    isSaving = true;
    error = null;
    notifyListeners();
    try {
      await _repo.savePlan(gymId, currentPlan!);
      plans = await _repo.getPlans(gymId, currentPlan!.createdBy);
    } catch (e) {
      error = 'Fehler beim Speichern: ' + e.toString();
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> renamePlan(
    String gymId,
    String planId,
    String newName,
  ) async {
    await _repo.renamePlan(gymId, planId, newName);
    final idx = plans.indexWhere((p) => p.id == planId);
    if (idx >= 0) {
      plans[idx] = plans[idx].copyWith(name: newName);
    }
    notifyListeners();
  }

  Future<void> deletePlan(String gymId, String planId) async {
    await _repo.deletePlan(gymId, planId);
    plans.removeWhere((p) => p.id == planId);
    if (activePlanId == planId) {
      activePlanId = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('activePlanId');
    }
    notifyListeners();
  }
}
