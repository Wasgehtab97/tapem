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
    : _repo =
          repo ?? TrainingPlanRepositoryImpl(FirestoreTrainingPlanSource()) {
    _loadActivePlanId();
  }

  Future<void> _loadActivePlanId() async {
    final prefs = await SharedPreferences.getInstance();
    activePlanId = prefs.getString('activePlanId');
    notifyListeners();
  }

  Future<void> setActivePlan(String id) async {
    activePlanId = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('activePlanId', id);
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

  void createNewPlan(String name, String createdBy, {required int weeks}) {
    debugPrint('➕ createNewPlan name=$name weeks=$weeks');
    final now = DateTime.now();
    final monday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final weekBlocks = [
      for (var i = 0; i < weeks; i++)
        WeekBlock(
          weekNumber: i + 1,
          days: [
            for (var d = 0; d < 7; d++)
              DayEntry(
                date: monday.add(Duration(days: i * 7 + d)),
                exercises: [],
              ),
          ],
        ),
    ];

    currentPlan = TrainingPlan(
      id: _uuid.v4(),
      name: name,
      createdAt: DateTime.now(),
      createdBy: createdBy,
      startDate: monday,
      weeks: weekBlocks,
    );
    debugPrint('✅ Created plan ${currentPlan!.id}');
    notifyListeners();
  }

  void setStartDate(DateTime monday) {
    final plan = currentPlan;
    if (plan == null) return;
    debugPrint('🗓 setStartDate $monday for plan ${plan.id}');
    for (final week in plan.weeks) {
      for (var i = 0; i < week.days.length; i++) {
        final day = week.days[i];
        week.days[i] = DayEntry(
          date: monday.add(Duration(days: (week.weekNumber - 1) * 7 + i)),
          exercises: day.exercises,
        );
      }
    }
    currentPlan = plan.copyWith(startDate: monday);
    notifyListeners();
  }

  void addDay(int week, DateTime date) {
    debugPrint('➕ addDay week=$week date=$date');
    final w = currentPlan?.weeks.firstWhere((e) => e.weekNumber == week);
    if (w == null) return;
    final exists = w.days.any(
      (d) =>
          d.date.year == date.year &&
          d.date.month == date.month &&
          d.date.day == date.day,
    );
    if (exists) return;
    w.days.add(DayEntry(date: date, exercises: []));
    w.days.sort((a, b) => a.date.compareTo(b.date));
    notifyListeners();
  }

  void removeDay(int week, DateTime date) {
    debugPrint('➖ removeDay week=$week date=$date');
    final w = currentPlan?.weeks.firstWhere((e) => e.weekNumber == week);
    if (w == null) return;
    w.days.removeWhere(
      (d) =>
          d.date.year == date.year &&
          d.date.month == date.month &&
          d.date.day == date.day,
    );
    notifyListeners();
  }

  void addExercise(int week, DateTime day, ExerciseEntry entry) {
    debugPrint('➕ addExercise week=$week day=$day ex=${entry.exerciseName}');
    final w = currentPlan?.weeks.firstWhere((e) => e.weekNumber == week);
    if (w == null) return;
    final d = w.days.firstWhere((e) => e.date == day);
    d.exercises.add(entry);
    notifyListeners();
  }

  void updateExercise(int week, DateTime day, int index, ExerciseEntry entry) {
    debugPrint('✏️ updateExercise week=$week day=$day index=$index');
    final w = currentPlan?.weeks.firstWhere((e) => e.weekNumber == week);
    if (w == null) return;
    final d = w.days.firstWhere((e) => e.date == day);
    if (index < 0 || index >= d.exercises.length) return;
    d.exercises[index] = entry;
    notifyListeners();
  }

  void removeExercise(int week, DateTime day, int index) {
    debugPrint('🗑 removeExercise week=$week day=$day index=$index');
    final w = currentPlan?.weeks.firstWhere((e) => e.weekNumber == week);
    if (w == null) return;
    final d = w.days.firstWhere((e) => e.date == day);
    if (index < 0 || index >= d.exercises.length) return;
    d.exercises.removeAt(index);
    notifyListeners();
  }

  void copyWeekExercises(int sourceWeek, List<int> targetWeeks) {
    final src = currentPlan?.weeks.firstWhere((w) => w.weekNumber == sourceWeek);
    if (src == null) return;
    for (final weekNo in targetWeeks) {
      final target =
          currentPlan?.weeks.firstWhere((w) => w.weekNumber == weekNo);
      if (target == null) continue;
      for (var i = 0; i < src.days.length && i < target.days.length; i++) {
        final exercises = [
          for (final ex in src.days[i].exercises)
            ExerciseEntry.fromMap(ex.toMap())
        ];
        target.days[i] =
            DayEntry(date: target.days[i].date, exercises: exercises);
      }
    }
    notifyListeners();
  }

  /// Copies all exercises from a specific day to multiple other days.
  ///
  /// [sourceWeek] and [sourceDay] identify the day to copy from. The
  /// [targets] map uses the week number as key and the day index within that
  /// week (0 = Monday) as value.
  void copyDayExercises(
    int sourceWeek,
    int sourceDay,
    Map<int, int> targets,
  ) {
    final srcWeek =
        currentPlan?.weeks.firstWhere((w) => w.weekNumber == sourceWeek);
    if (srcWeek == null || sourceDay < 0 || sourceDay >= srcWeek.days.length) {
      return;
    }
    final srcDay = srcWeek.days[sourceDay];
    final clone = [
      for (final ex in srcDay.exercises)
        ExerciseEntry.fromMap(ex.toMap()),
    ];

    targets.forEach((weekNo, dayIdx) {
      final targetWeek =
          currentPlan?.weeks.firstWhere((w) => w.weekNumber == weekNo);
      if (targetWeek == null ||
          dayIdx < 0 ||
          dayIdx >= targetWeek.days.length) {
        return;
      }
      final date = targetWeek.days[dayIdx].date;
      targetWeek.days[dayIdx] = DayEntry(date: date, exercises: [
        for (final ex in clone) ExerciseEntry.fromMap(ex.toMap()),
      ]);
    });

    notifyListeners();
  }

  void moveExercise(
    int srcWeek,
    DateTime srcDay,
    int index,
    int destWeek,
    DateTime destDay,
  ) {
    final srcW = currentPlan?.weeks.firstWhere((w) => w.weekNumber == srcWeek);
    final destW =
        currentPlan?.weeks.firstWhere((w) => w.weekNumber == destWeek);
    if (srcW == null || destW == null) return;
    final sDay = srcW.days.firstWhere((d) => d.date == srcDay);
    final dDay = destW.days.firstWhere((d) => d.date == destDay);
    if (index < 0 || index >= sDay.exercises.length) return;
    final ex = sDay.exercises.removeAt(index);
    dDay.exercises.add(ex);
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('activePlanId');
    }
    notifyListeners();
  }
}
