import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/features/nutrition/data/nutrition_repository.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_goal.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_log.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_year_summary.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_macros.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_entry.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_totals.dart';
import 'package:tapem/features/nutrition/domain/utils/nutrition_dates.dart';
import 'package:tapem/features/nutrition/domain/utils/nutrition_recipe_math.dart';
import 'package:tapem/features/nutrition/domain/services/nutrition_status_service.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_recipe.dart';

class NutritionProvider extends ChangeNotifier {
  final NutritionRepository _repo;
  final NutritionStatusService _statusService;
  NutritionProvider({
    required NutritionRepository repository,
    NutritionStatusService? statusService,
  }) : _repo = repository,
       _statusService = statusService ?? NutritionStatusService();

  DateTime _selectedDate = nutritionStartOfDay(DateTime.now());
  NutritionGoal? _goal;
  NutritionLog? _log;
  NutritionYearSummary? _yearSummary;
  List<NutritionRecipe> _recipes = [];
  bool _isLoadingDay = false;
  bool _isLoadingYear = false;
  bool _isLoadingRecipes = false;
  Object? _error;

  DateTime get selectedDate => _selectedDate;
  String get selectedDateKey => toNutritionDateKey(_selectedDate);
  NutritionGoal? get goal => _goal;
  NutritionLog? get log => _log;
  NutritionYearSummary? get yearSummary => _yearSummary;
  List<NutritionRecipe> get recipes => _recipes;
  bool get isLoadingDay => _isLoadingDay;
  bool get isLoadingYear => _isLoadingYear;
  bool get isLoadingRecipes => _isLoadingRecipes;
  Object? get error => _error;

  void setSelectedDate(DateTime date) {
    _selectedDate = nutritionStartOfDay(date);
    notifyListeners();
  }

  Future<NutritionGoal?> _resolveGoalForDate(String uid, String dateKey) async {
    NutritionGoal? goal = (_goal != null && _goal!.dateKey == dateKey)
        ? _goal
        : await _repo.fetchGoal(uid, dateKey);
    goal ??= await _repo.fetchDefaultGoal(uid);
    if (goal != null && goal.dateKey != dateKey) {
      goal = NutritionGoal(
        dateKey: dateKey,
        kcal: goal.kcal,
        macros: goal.macros,
        source: goal.source,
        updatedAt: goal.updatedAt,
      );
    }
    return goal;
  }

  Future<void> loadDay(String uid, DateTime date) async {
    _isLoadingDay = true;
    _error = null;
    notifyListeners();
    try {
      final dateKey = toNutritionDateKey(date);
      final goal =
          await _repo.fetchGoal(uid, dateKey) ??
          await _repo.fetchDefaultGoal(uid);
      if (goal != null && goal.dateKey != dateKey) {
        _goal = NutritionGoal(
          dateKey: dateKey,
          kcal: goal.kcal,
          macros: goal.macros,
          source: goal.source,
          updatedAt: goal.updatedAt,
        );
      } else {
        _goal = goal;
      }
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

  Future<void> loadRecipes(String uid) async {
    _isLoadingRecipes = true;
    _error = null;
    notifyListeners();
    try {
      _recipes = await _repo.fetchRecipes(uid);
    } catch (e) {
      _error = e;
    } finally {
      _isLoadingRecipes = false;
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
      await _repo.upsertDefaultGoal(uid, goal);
      _goal = goal;
      final existingTotal = _log?.total.kcal ?? 0;
      await _repo.updateYearDay(
        uid,
        date.year,
        dateKey,
        _statusService.statusFor(totalKcal: existingTotal, targetKcal: kcal),
        goal: kcal,
        total: existingTotal,
      );
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
    await addEntries(uid: uid, date: date, entriesToAdd: [entry]);
  }

  Future<void> addEntries({
    required String uid,
    required DateTime date,
    required List<NutritionEntry> entriesToAdd,
  }) async {
    if (entriesToAdd.isEmpty) return;
    _error = null;
    final previousLog = _log;
    final previousGoal = _goal;
    try {
      final dateKey = toNutritionDateKey(date);
      final existingLog = (_log != null && _log!.dateKey == dateKey)
          ? _log
          : await _repo.fetchLog(uid, dateKey);
      final entries = <NutritionEntry>[
        ...(existingLog?.entries ?? const <NutritionEntry>[]),
        ...entriesToAdd,
      ];
      if (entries.length > 50) {
        throw StateError('Too many entries for one day.');
      }
      final deltaKcal = entriesToAdd.fold<int>(0, (sum, e) => sum + e.kcal);
      final deltaProtein = entriesToAdd.fold<int>(
        0,
        (sum, e) => sum + e.protein,
      );
      final deltaCarbs = entriesToAdd.fold<int>(0, (sum, e) => sum + e.carbs);
      final deltaFat = entriesToAdd.fold<int>(0, (sum, e) => sum + e.fat);
      final totalKcal = (existingLog?.total.kcal ?? 0) + deltaKcal;
      final totalProtein = (existingLog?.total.protein ?? 0) + deltaProtein;
      final totalCarbs = (existingLog?.total.carbs ?? 0) + deltaCarbs;
      final totalFat = (existingLog?.total.fat ?? 0) + deltaFat;
      final totals = NutritionTotals(
        kcal: totalKcal,
        protein: totalProtein,
        carbs: totalCarbs,
        fat: totalFat,
      );
      final goal = await _resolveGoalForDate(uid, dateKey);
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
      final year = date.year;
      await _repo.updateYearDay(
        uid,
        year,
        dateKey,
        status,
        goal: goal?.kcal ?? 0,
        total: totalKcal,
      );
    } catch (e) {
      _error = e;
      _log = previousLog;
      _goal = previousGoal;
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> removeEntry({
    required String uid,
    required DateTime date,
    required int index,
  }) async {
    _error = null;
    final previousLog = _log;
    try {
      final dateKey = toNutritionDateKey(date);
      final existingLog = (_log != null && _log!.dateKey == dateKey)
          ? _log
          : await _repo.fetchLog(uid, dateKey);
      if (existingLog == null ||
          index < 0 ||
          index >= existingLog.entries.length) {
        return;
      }
      final entries = List<NutritionEntry>.from(existingLog.entries)
        ..removeAt(index);
      final totals = NutritionTotals(
        kcal: entries.fold(0, (s, e) => s + e.kcal),
        protein: entries.fold(0, (s, e) => s + e.protein),
        carbs: entries.fold(0, (s, e) => s + e.carbs),
        fat: entries.fold(0, (s, e) => s + e.fat),
      );
      final goal = await _resolveGoalForDate(uid, dateKey);
      final status = _statusService.statusFor(
        totalKcal: totals.kcal,
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
      await _repo.updateYearDay(
        uid,
        date.year,
        dateKey,
        status,
        goal: goal?.kcal ?? 0,
        total: totals.kcal,
      );
    } catch (e) {
      _error = e;
      _log = previousLog;
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> saveRecipe({
    required String uid,
    required NutritionRecipe recipe,
  }) async {
    try {
      final id = await _repo.upsertRecipe(uid, recipe);
      final updated = recipe.id.isEmpty ? recipe.copyWith(id: id) : recipe;
      final idx = _recipes.indexWhere((r) => r.id == id);
      if (idx >= 0) {
        _recipes[idx] = updated;
      } else {
        _recipes = [..._recipes, updated];
      }
      notifyListeners();
    } catch (e) {
      _error = e;
      rethrow;
    }
  }

  Future<void> deleteRecipe({required String uid, required String id}) async {
    try {
      await _repo.deleteRecipe(uid, id);
      _recipes = _recipes.where((r) => r.id != id).toList();
      notifyListeners();
    } catch (e) {
      _error = e;
      rethrow;
    }
  }

  Future<void> addRecipeToMeal({
    required String uid,
    required DateTime date,
    required NutritionRecipe recipe,
    required String meal,
    double factor = 1.0,
  }) async {
    if (recipe.ingredients.isEmpty) return;
    final entries = buildRecipeIngredientEntries(
      recipeName: recipe.name,
      meal: meal,
      ingredients: recipe.ingredients,
      factor: factor,
      recipeId: recipe.id.isEmpty ? null : recipe.id,
    );
    if (entries.isEmpty) return;
    await addEntries(uid: uid, date: date, entriesToAdd: entries);
  }

  Future<void> updateEntry({
    required String uid,
    required DateTime date,
    required int index,
    required NutritionEntry entry,
  }) async {
    _error = null;
    final previousLog = _log;
    try {
      final dateKey = toNutritionDateKey(date);
      final existingLog = (_log != null && _log!.dateKey == dateKey)
          ? _log
          : await _repo.fetchLog(uid, dateKey);
      if (existingLog == null ||
          index < 0 ||
          index >= existingLog.entries.length) {
        return;
      }
      final entries = List<NutritionEntry>.from(existingLog.entries)
        ..[index] = entry;
      final totals = NutritionTotals(
        kcal: entries.fold(0, (s, e) => s + e.kcal),
        protein: entries.fold(0, (s, e) => s + e.protein),
        carbs: entries.fold(0, (s, e) => s + e.carbs),
        fat: entries.fold(0, (s, e) => s + e.fat),
      );
      final goal = await _resolveGoalForDate(uid, dateKey);
      final status = _statusService.statusFor(
        totalKcal: totals.kcal,
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
      await _repo.updateYearDay(
        uid,
        date.year,
        dateKey,
        status,
        goal: goal?.kcal ?? 0,
        total: totals.kcal,
      );
    } catch (e) {
      _error = e;
      _log = previousLog;
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
