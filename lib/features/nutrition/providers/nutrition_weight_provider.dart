import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/features/nutrition/data/nutrition_repository.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_weight_bucket.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_weight_log.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_weight_meta.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_weight_range.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_weight_year_summary.dart';
import 'package:tapem/features/nutrition/domain/services/nutrition_weight_aggregation_service.dart';
import 'package:tapem/features/nutrition/domain/utils/nutrition_dates.dart';

class NutritionWeightProvider extends ChangeNotifier {
  NutritionWeightProvider({
    required NutritionRepository repository,
    NutritionWeightAggregationService? aggregationService,
    DateTime Function()? now,
  }) : _repo = repository,
       _aggregationService =
           aggregationService ?? const NutritionWeightAggregationService(),
       _now = now ?? DateTime.now {
    final initial = nutritionStartOfDay(_now());
    _selectedDate = initial;
    _selectedDateKey = toNutritionDateKey(initial);
  }

  final NutritionRepository _repo;
  final NutritionWeightAggregationService _aggregationService;
  final DateTime Function() _now;

  NutritionWeightRange _selectedRange = NutritionWeightRange.week;
  List<NutritionWeightBucket> _chartBuckets = const [];
  final Map<int, NutritionWeightYearSummary> _yearCache = {};

  String? _activeUid;
  NutritionWeightMeta? _currentMeta;
  late DateTime _selectedDate;
  late String _selectedDateKey;
  double? _selectedKg;
  double? _todayKg;
  String? _todayDateKey;
  bool _isLoading = false;
  bool _isSaving = false;
  Object? _error;

  NutritionWeightRange get selectedRange => _selectedRange;
  List<NutritionWeightBucket> get chartBuckets => _chartBuckets;
  DateTime get selectedDate => _selectedDate;
  String get selectedDateKey => _selectedDateKey;
  double? get selectedKg => _selectedKg;
  double? get todayKg => _todayKg;
  String? get todayDateKey => _todayDateKey;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  Object? get error => _error;

  @visibleForTesting
  Map<int, NutritionWeightYearSummary> get yearCache =>
      Map<int, NutritionWeightYearSummary>.unmodifiable(_yearCache);

  Future<void> load(String uid) async {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) return;
    _switchActiveUidIfNeeded(normalizedUid);

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final today = nutritionStartOfDay(_now());
      final todayKey = toNutritionDateKey(today);

      final current = await _repo.fetchCurrentWeight(normalizedUid);
      _currentMeta = current;
      await _ensureYearsLoaded(normalizedUid, referenceDate: _selectedDate);

      _todayDateKey = todayKey;
      _todayKg = _resolveWeightForDate(
        dateKey: todayKey,
        currentKg: current?.kg,
        currentDateKey: current?.dateKey,
      );
      _selectedKg = _resolveWeightForDate(
        dateKey: _selectedDateKey,
        currentKg: current?.kg,
        currentDateKey: current?.dateKey,
      );
      _rebuildBuckets(referenceDate: _selectedDate);
    } catch (e) {
      _error = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveTodayWeight(String uid, double kg) async {
    await saveWeightForDate(uid, kg, date: _now());
  }

  Future<void> saveSelectedWeight(String uid, double kg) async {
    await saveWeightForDate(uid, kg, date: _selectedDate);
  }

  Future<void> saveWeightForDate(
    String uid,
    double kg, {
    required DateTime date,
  }) async {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) return;
    _switchActiveUidIfNeeded(normalizedUid);

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final reference = nutritionStartOfDay(date);
      final today = nutritionStartOfDay(_now());
      final todayKey = toNutritionDateKey(today);
      final dateKey = toNutritionDateKey(reference);
      final normalizedKg = _normalizeWeightKg(kg);
      final timestamp = DateTime.now();

      await _repo.upsertWeightLog(
        normalizedUid,
        NutritionWeightLog(
          dateKey: dateKey,
          kg: normalizedKg,
          source: 'manual',
          updatedAt: timestamp,
        ),
      );
      await _repo.upsertWeightYearDay(
        normalizedUid,
        reference.year,
        dateKey,
        kg: normalizedKg,
        updatedAt: timestamp,
      );

      final shouldUpdateCurrentMeta =
          _currentMeta == null || dateKey.compareTo(_currentMeta!.dateKey) >= 0;
      if (shouldUpdateCurrentMeta) {
        await _repo.upsertCurrentWeight(
          normalizedUid,
          kg: normalizedKg,
          dateKey: dateKey,
          updatedAt: timestamp,
        );
        _currentMeta = NutritionWeightMeta(
          kg: normalizedKg,
          dateKey: dateKey,
          updatedAt: timestamp,
        );
      }

      _upsertCachedYearDay(
        year: reference.year,
        dateKey: dateKey,
        kg: normalizedKg,
        updatedAt: timestamp,
      );
      _selectedDate = reference;
      _selectedDateKey = dateKey;
      _selectedKg = normalizedKg;

      _todayDateKey = todayKey;
      _todayKg = _resolveWeightForDate(
        dateKey: todayKey,
        currentKg: _currentMeta?.kg,
        currentDateKey: _currentMeta?.dateKey,
      );

      await _ensureYearsLoaded(normalizedUid, referenceDate: reference);
      _rebuildBuckets(referenceDate: reference);
    } catch (e) {
      _error = e;
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> setSelectedDate(DateTime date, {String? uid}) async {
    final nextDate = nutritionStartOfDay(date);
    final nextKey = toNutritionDateKey(nextDate);
    if (nextKey == _selectedDateKey) return;

    _selectedDate = nextDate;
    _selectedDateKey = nextKey;
    _selectedKg = _resolveWeightForDate(
      dateKey: nextKey,
      currentKg: _currentMeta?.kg,
      currentDateKey: _currentMeta?.dateKey,
    );
    _rebuildBuckets(referenceDate: _selectedDate);
    notifyListeners();

    final normalizedUid = (uid ?? _activeUid)?.trim();
    if (normalizedUid == null || normalizedUid.isEmpty) return;
    if (_activeUid != normalizedUid) {
      _switchActiveUidIfNeeded(normalizedUid);
      _selectedDate = nextDate;
      _selectedDateKey = nextKey;
    }

    if (!_hasMissingYears(referenceDate: _selectedDate)) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _ensureYearsLoaded(normalizedUid, referenceDate: _selectedDate);
      _selectedKg = _resolveWeightForDate(
        dateKey: _selectedDateKey,
        currentKg: _currentMeta?.kg,
        currentDateKey: _currentMeta?.dateKey,
      );
      _rebuildBuckets(referenceDate: _selectedDate);
    } catch (e) {
      _error = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> shiftSelectedDate(int dayOffset, {String? uid}) async {
    if (dayOffset == 0) return;
    final next = _selectedDate.add(Duration(days: dayOffset));
    await setSelectedDate(next, uid: uid);
  }

  Future<void> setRange(NutritionWeightRange range) async {
    if (_selectedRange == range) return;
    _selectedRange = range;
    notifyListeners();

    final uid = _activeUid;
    if (uid == null || uid.isEmpty) return;
    await reloadSeries(uid);
  }

  Future<void> reloadSeries(String uid) async {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) return;
    _switchActiveUidIfNeeded(normalizedUid);

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _ensureYearsLoaded(normalizedUid, referenceDate: _selectedDate);
      _rebuildBuckets(referenceDate: _selectedDate);
    } catch (e) {
      _error = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _switchActiveUidIfNeeded(String uid) {
    if (_activeUid == uid) return;
    _activeUid = uid;
    _currentMeta = null;
    _yearCache.clear();
    _chartBuckets = const [];
    final today = nutritionStartOfDay(_now());
    _selectedDate = today;
    _selectedDateKey = toNutritionDateKey(today);
    _selectedKg = null;
    _todayKg = null;
    _todayDateKey = null;
  }

  Future<void> _ensureYearsLoaded(
    String uid, {
    required DateTime referenceDate,
  }) async {
    final neededYears =
        _aggregationService
            .requiredYearsForRange(
              range: _selectedRange,
              referenceDate: referenceDate,
            )
            .toList()
          ..sort();

    for (final year in neededYears) {
      if (_yearCache.containsKey(year)) continue;
      final summary = await _repo.fetchWeightYearSummary(uid, year);
      _yearCache[year] =
          summary ?? NutritionWeightYearSummary(year: year, days: const {});
    }
  }

  bool _hasMissingYears({required DateTime referenceDate}) {
    final neededYears = _aggregationService.requiredYearsForRange(
      range: _selectedRange,
      referenceDate: referenceDate,
    );
    for (final year in neededYears) {
      if (!_yearCache.containsKey(year)) {
        return true;
      }
    }
    return false;
  }

  double? _resolveWeightForDate({
    required String dateKey,
    double? currentKg,
    String? currentDateKey,
  }) {
    final years = _yearCache.keys.toList()..sort();
    for (final year in years) {
      final day = _yearCache[year]?.days[dateKey];
      if (day != null) return day.kg;
    }
    if (currentDateKey == dateKey && currentKg != null) {
      return currentKg;
    }
    return null;
  }

  void _rebuildBuckets({required DateTime referenceDate}) {
    final dailyWeights = _flattenDailyWeightsFromCache();
    _chartBuckets = _aggregationService.aggregateAverages(
      dailyWeights: dailyWeights,
      range: _selectedRange,
      referenceDate: referenceDate,
    );
  }

  Map<String, double> _flattenDailyWeightsFromCache() {
    final flattened = <String, double>{};
    final years = _yearCache.keys.toList()..sort();
    for (final year in years) {
      final summary = _yearCache[year];
      if (summary == null) continue;
      for (final entry in summary.days.entries) {
        flattened[entry.key] = entry.value.kg;
      }
    }
    return flattened;
  }

  void _upsertCachedYearDay({
    required int year,
    required String dateKey,
    required double kg,
    DateTime? updatedAt,
  }) {
    final current = _yearCache[year];
    final nextDays = <String, NutritionWeightYearDay>{
      ...?current?.days,
      dateKey: NutritionWeightYearDay(
        kg: kg,
        updatedAt: updatedAt ?? DateTime.now(),
      ),
    };
    _yearCache[year] = NutritionWeightYearSummary(year: year, days: nextDays);
  }

  double _normalizeWeightKg(double kg) {
    if (!kg.isFinite || kg < 20 || kg > 400) {
      throw StateError('Gewicht ausserhalb erlaubter Range (20-400 kg).');
    }
    return double.parse(kg.toStringAsFixed(2));
  }
}

final nutritionWeightProvider = ChangeNotifierProvider<NutritionWeightProvider>(
  (ref) {
    final provider = NutritionWeightProvider(repository: NutritionRepository());
    ref.onDispose(provider.dispose);
    return provider;
  },
);
