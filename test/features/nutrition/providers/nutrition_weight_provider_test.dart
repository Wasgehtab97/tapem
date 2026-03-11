import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/nutrition/data/nutrition_repository.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_weight_log.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_weight_meta.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_weight_range.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_weight_year_summary.dart';
import 'package:tapem/features/nutrition/providers/nutrition_weight_provider.dart';

class _FakeNutritionRepository extends NutritionRepository {
  _FakeNutritionRepository() : super(firestore: FakeFirebaseFirestore());

  final Map<int, NutritionWeightYearSummary> summaries = {};
  NutritionWeightMeta? currentMeta;

  int fetchWeightYearSummaryCalls = 0;
  final List<int> fetchedYears = [];

  NutritionWeightLog? lastUpsertedLog;
  Map<String, dynamic>? lastUpsertedYearDay;
  NutritionWeightMeta? lastUpsertedMeta;

  @override
  Future<NutritionWeightMeta?> fetchCurrentWeight(String uid) async {
    return currentMeta;
  }

  @override
  Future<NutritionWeightYearSummary?> fetchWeightYearSummary(
    String uid,
    int year,
  ) async {
    fetchWeightYearSummaryCalls++;
    fetchedYears.add(year);
    return summaries[year];
  }

  @override
  Future<void> upsertWeightLog(String uid, NutritionWeightLog log) async {
    lastUpsertedLog = log;
  }

  @override
  Future<void> upsertWeightYearDay(
    String uid,
    int year,
    String dateKey, {
    required num kg,
    DateTime? updatedAt,
  }) async {
    final rounded = double.parse(kg.toStringAsFixed(2));
    lastUpsertedYearDay = {
      'year': year,
      'dateKey': dateKey,
      'kg': rounded,
      'updatedAt': updatedAt,
    };

    final current = summaries[year];
    final nextDays = <String, NutritionWeightYearDay>{
      ...?current?.days,
      dateKey: NutritionWeightYearDay(kg: rounded, updatedAt: updatedAt),
    };
    summaries[year] = NutritionWeightYearSummary(year: year, days: nextDays);
  }

  @override
  Future<void> upsertCurrentWeight(
    String uid, {
    required num kg,
    required String dateKey,
    DateTime? updatedAt,
  }) async {
    final rounded = double.parse(kg.toStringAsFixed(2));
    lastUpsertedMeta = NutritionWeightMeta(
      kg: rounded,
      dateKey: dateKey,
      updatedAt: updatedAt,
    );
    currentMeta = lastUpsertedMeta;
  }
}

void main() {
  test(
    'load + setRange uses year cache and only fetches missing years',
    () async {
      final repo = _FakeNutritionRepository();
      repo.currentMeta = NutritionWeightMeta(
        kg: 82.0,
        dateKey: '20260305',
        updatedAt: DateTime(2026, 3, 5),
      );
      repo.summaries[2025] = NutritionWeightYearSummary(
        year: 2025,
        days: const {'20251220': NutritionWeightYearDay(kg: 84.0)},
      );
      repo.summaries[2026] = NutritionWeightYearSummary(
        year: 2026,
        days: const {'20260305': NutritionWeightYearDay(kg: 82.0)},
      );

      final provider = NutritionWeightProvider(
        repository: repo,
        now: () => DateTime(2026, 3, 5),
      );

      await provider.load('user1');
      expect(provider.todayKg, 82.0);
      expect(provider.todayDateKey, '20260305');
      expect(provider.chartBuckets, isNotEmpty);
      expect(repo.fetchedYears.toSet(), containsAll(<int>{2025, 2026}));
      final callsAfterLoad = repo.fetchWeightYearSummaryCalls;

      await provider.setRange(NutritionWeightRange.month);
      expect(repo.fetchWeightYearSummaryCalls, callsAfterLoad);

      await provider.setRange(NutritionWeightRange.year);
      expect(repo.fetchWeightYearSummaryCalls, callsAfterLoad + 3);
      expect(
        provider.yearCache.keys.toSet(),
        containsAll(<int>{2022, 2023, 2024, 2025, 2026}),
      );
    },
  );

  test('saveTodayWeight persists and updates in-memory cache', () async {
    final repo = _FakeNutritionRepository();
    repo.summaries[2025] = NutritionWeightYearSummary(
      year: 2025,
      days: const {},
    );
    repo.summaries[2026] = NutritionWeightYearSummary(
      year: 2026,
      days: const {},
    );

    final provider = NutritionWeightProvider(
      repository: repo,
      now: () => DateTime(2026, 3, 5),
    );

    await provider.load('user1');
    await provider.saveTodayWeight('user1', 83.256);

    expect(provider.todayDateKey, '20260305');
    expect(provider.todayKg, 83.26);
    expect(repo.lastUpsertedLog, isNotNull);
    expect(repo.lastUpsertedLog!.kg, 83.26);
    expect(repo.lastUpsertedYearDay, isNotNull);
    expect(repo.lastUpsertedMeta, isNotNull);
    expect(provider.yearCache[2026]?.days['20260305']?.kg, 83.26);
    expect(provider.chartBuckets, isNotEmpty);
  });

  test(
    'setSelectedDate + saveSelectedWeight writes selected day without overriding current meta for past days',
    () async {
      final repo = _FakeNutritionRepository();
      repo.currentMeta = NutritionWeightMeta(
        kg: 82.0,
        dateKey: '20260305',
        updatedAt: DateTime(2026, 3, 5),
      );
      repo.summaries[2025] = NutritionWeightYearSummary(
        year: 2025,
        days: const {},
      );
      repo.summaries[2026] = NutritionWeightYearSummary(
        year: 2026,
        days: const {'20260305': NutritionWeightYearDay(kg: 82.0)},
      );

      final provider = NutritionWeightProvider(
        repository: repo,
        now: () => DateTime(2026, 3, 5),
      );

      await provider.load('user1');
      await provider.setSelectedDate(DateTime(2026, 3, 1), uid: 'user1');
      await provider.saveSelectedWeight('user1', 81.25);

      expect(provider.selectedDateKey, '20260301');
      expect(provider.selectedKg, 81.25);
      expect(provider.todayDateKey, '20260305');
      expect(provider.todayKg, 82.0);
      expect(repo.lastUpsertedLog?.dateKey, '20260301');
      expect(repo.lastUpsertedYearDay?['dateKey'], '20260301');
      expect(
        provider.yearCache[2026]?.days['20260301']?.kg,
        closeTo(81.25, 0.0001),
      );
      expect(repo.lastUpsertedMeta, isNull);
    },
  );

  test(
    'persists across provider recreation via Firestore repository',
    () async {
      final firestore = FakeFirebaseFirestore();
      final repo = NutritionRepository(firestore: firestore);

      final writer = NutritionWeightProvider(
        repository: repo,
        now: () => DateTime(2026, 3, 5),
      );
      await writer.load('user_persist');
      await writer.saveTodayWeight('user_persist', 80.4);

      final reader = NutritionWeightProvider(
        repository: repo,
        now: () => DateTime(2026, 3, 5),
      );
      await reader.load('user_persist');

      expect(reader.todayDateKey, '20260305');
      expect(reader.todayKg, closeTo(80.4, 0.0001));
      expect(reader.chartBuckets, isNotEmpty);
    },
  );
}
