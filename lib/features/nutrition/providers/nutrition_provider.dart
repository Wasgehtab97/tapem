import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/nutrition_repository.dart';
import '../domain/models/nutrition_goal.dart';
import '../domain/models/nutrition_log.dart';
import '../domain/models/nutrition_year_summary.dart';
import '../domain/models/nutrition_macros.dart';
import '../domain/models/nutrition_entry.dart';
import '../domain/models/nutrition_totals.dart';
import '../domain/utils/nutrition_dates.dart';
import '../domain/services/nutrition_status_service.dart';

class NutritionProvider extends ChangeNotifier {
  final NutritionRepository _repo;
  final NutritionStatusService _statusService;
  NutritionProvider({
    required NutritionRepository repository,
    NutritionStatusService? statusService,
  })  : _repo = repository,
        _statusService = statusService ?? NutritionStatusService();

  DateTime _selectedDate = nutritionStartOfDay(DateTime.now());
  NutritionGoal? _goal;
  NutritionLog? _log;
  NutritionYearSummary? _yearSummary;
  bool _isLoadingDay = false;
  bool _isLoadingYear = false;
  Object? _error;

  DateTime get selectedDate => _selectedDate;
  String get selectedDateKey => toNutritionDateKey(_selectedDate);
  NutritionGoal? get goal => _goal;
  NutritionLog? get log => _log;
  NutritionYearSummary? get yearSummary => _yearSummary;
  bool get isLoadingDay => _isLoadingDay;
  bool get isLoadingYear => _isLoadingYear;
  Object? get error => _error;

  void setSelectedDate(DateTime date) {
    _selectedDate = nutritionStartOfDay(date);
    notifyListeners();
  }

  Future<void> loadDay(String uid, DateTime date) async {
    _isLoadingDay = true;
    _error = null;
    notifyListeners();
    try {
      final dateKey = toNutritionDateKey(date);
      _goal = await _repo.fetchGoal(uid, dateKey);
      _log = await _repo.fetchLog(uid, dateKey);
      _selectedDate = nutritionStartOfDay(date);
    } catch (e) {
      _error = e;
    } finally {
      _isLoadingDay = false;
      notifyListeners();
    }
  }

  Future<void> loadYear(String uid, int year) async {
    _isLoadingYear = true;
    _error = null;
    notifyListeners();
    try {
      _yearSummary = await _repo.fetchYearSummary(uid, year);
    } catch (e) {
      _error = e;
    } finally {
      _isLoadingYear = false;
      notifyListeners();
    }
  }

  Future<void> saveGoal({
    required String uid,
    required DateTime date,
    required int kcal,
    required NutritionMacros macros,
    String source = 'manual',
  }) async {
    _error = null;
    notifyListeners();
    try {
      final dateKey = toNutritionDateKey(date);
      final goal = NutritionGoal(
        dateKey: dateKey,
        kcal: kcal,
        macros: macros,
        source: source,
        updatedAt: DateTime.now(),
      );
      await _repo.upsertGoal(uid, goal);
      _goal = goal;
    } catch (e) {
      _error = e;
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> addEntry({
    required String uid,
    required DateTime date,
    required NutritionEntry entry,
  }) async {
    _error = null;
    final previousLog = _log;
    final previousGoal = _goal;
    try {
      final dateKey = toNutritionDateKey(date);
      final existingLog =
          (_log != null && _log!.dateKey == dateKey)
              ? _log
              : await _repo.fetchLog(uid, dateKey);
      final entries = <NutritionEntry>[
        ...(existingLog?.entries ?? const <NutritionEntry>[]),
        entry,
      ];
      if (entries.length > 50) {
        throw StateError('Too many entries for one day.');
      }
      final totalKcal =
          (existingLog?.total.kcal ?? 0) + entry.kcal;
      final totalProtein =
          (existingLog?.total.protein ?? 0) + entry.protein;
      final totalCarbs =
          (existingLog?.total.carbs ?? 0) + entry.carbs;
      final totalFat = (existingLog?.total.fat ?? 0) + entry.fat;
      final totals = NutritionTotals(
        kcal: totalKcal,
        protein: totalProtein,
        carbs: totalCarbs,
        fat: totalFat,
      );
      final goal =
          (_goal != null && _goal!.dateKey == dateKey)
              ? _goal
              : await _repo.fetchGoal(uid, dateKey);
      final status = _statusService.statusFor(
        totalKcal: totalKcal,
        targetKcal: goal?.kcal ?? 0,
      );
      final log = NutritionLog(
        dateKey: dateKey,
        total: totals,
        entries: entries,
        status: status,
        updatedAt: DateTime.now(),
      );
      _log = log;
      _goal = goal;
      notifyListeners();
      await _repo.upsertLog(uid, log);
      if (existingLog?.status != status) {
        final year = date.year;
        await _repo.updateYearStatus(uid, year, dateKey, status);
      }
    } catch (e) {
      _error = e;
      _log = previousLog;
      _goal = previousGoal;
      rethrow;
    } finally {
      notifyListeners();
    }
  }
}

final nutritionProvider = ChangeNotifierProvider<NutritionProvider>((ref) {
  final provider = NutritionProvider(repository: NutritionRepository());
  ref.onDispose(provider.dispose);
  return provider;
});
