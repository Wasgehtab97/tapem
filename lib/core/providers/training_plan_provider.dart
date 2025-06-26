import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../features/training_plan/data/repositories/training_plan_repository_impl.dart';
import '../../features/training_plan/data/sources/firestore_training_plan_source.dart';
import '../../features/training_plan/domain/models/exercise_entry.dart';
import '../../features/training_plan/domain/models/training_plan.dart';
import '../../features/training_plan/domain/models/week_block.dart';
import '../../features/training_plan/domain/models/day_entry.dart';
import '../../features/training_plan/domain/repositories/training_plan_repository.dart';

class TrainingPlanProvider extends ChangeNotifier {
  final TrainingPlanRepository _repo;
  final Uuid _uuid = const Uuid();

  List<TrainingPlan> plans = [];
  TrainingPlan? currentPlan;
  bool isLoading = false;
  String? error;

  TrainingPlanProvider({TrainingPlanRepository? repo})
    : _repo = repo ?? TrainingPlanRepositoryImpl(FirestoreTrainingPlanSource());

  Future<void> loadPlans(String gymId) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      plans = await _repo.getPlans(gymId);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void createNewPlan(String name) {
    final weeks = [for (var i = 1; i <= 13; i++) _emptyWeek(i)];
    currentPlan = TrainingPlan(id: _uuid.v4(), name: name, weeks: weeks);
    notifyListeners();
  }

  WeekBlock _emptyWeek(int number) {
    return WeekBlock(
      weekNumber: number,
      days: [
        DayEntry(day: 'Mo', exercises: []),
        DayEntry(day: 'Do', exercises: []),
      ],
    );
  }

  void addExercise(int week, String day, ExerciseEntry entry) {
    final w = currentPlan?.weeks.firstWhere((e) => e.weekNumber == week);
    if (w == null) return;
    final d = w.days.firstWhere((e) => e.day == day);
    d.exercises.add(entry);
    notifyListeners();
  }

  Future<void> saveCurrentPlan(String gymId) async {
    if (currentPlan == null) return;
    await _repo.savePlan(gymId, currentPlan!);
  }
}
