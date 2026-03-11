import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_weight_range.dart';
import 'package:tapem/features/nutrition/domain/services/nutrition_weight_aggregation_service.dart';

void main() {
  const service = NutritionWeightAggregationService();

  test('aggregates sparse daily data into weekly averages', () {
    final buckets = service.aggregateAverages(
      dailyWeights: {'20260303': 80, '20260305': 82, '20260224': 84},
      range: NutritionWeightRange.week,
      referenceDate: DateTime(2026, 3, 5),
      bucketCount: 2,
    );

    expect(buckets, hasLength(2));
    expect(buckets[0].avgKg, 84.0);
    expect(buckets[0].sampleCount, 1);
    expect(buckets[1].avgKg, 81.0);
    expect(buckets[1].sampleCount, 2);
  });

  test('aggregates into monthly averages and skips empty buckets', () {
    final buckets = service.aggregateAverages(
      dailyWeights: {'20260102': 80, '20260120': 82, '20260305': 84},
      range: NutritionWeightRange.month,
      referenceDate: DateTime(2026, 3, 20),
      bucketCount: 3,
    );

    expect(buckets, hasLength(2));
    expect(buckets[0].label, '01/2026');
    expect(buckets[0].avgKg, 81.0);
    expect(buckets[1].label, '03/2026');
    expect(buckets[1].avgKg, 84.0);
  });

  test('aggregates across quarter boundaries over year change', () {
    final buckets = service.aggregateAverages(
      dailyWeights: {'20251110': 90, '20251215': 88, '20260110': 86},
      range: NutritionWeightRange.quarter,
      referenceDate: DateTime(2026, 1, 15),
      bucketCount: 2,
    );

    expect(buckets, hasLength(2));
    expect(buckets[0].label, 'Q4 2025');
    expect(buckets[0].avgKg, 89.0);
    expect(buckets[1].label, 'Q1 2026');
    expect(buckets[1].avgKg, 86.0);
  });

  test('reports required years for ranges', () {
    final weekYears = service.requiredYearsForRange(
      range: NutritionWeightRange.week,
      referenceDate: DateTime(2026, 1, 2),
    );
    expect(weekYears, containsAll(<int>{2025, 2026}));

    final monthYears = service.requiredYearsForRange(
      range: NutritionWeightRange.month,
      referenceDate: DateTime(2026, 3, 1),
    );
    expect(monthYears, containsAll(<int>{2025, 2026}));

    final yearYears = service.requiredYearsForRange(
      range: NutritionWeightRange.year,
      referenceDate: DateTime(2026, 3, 1),
    );
    expect(yearYears, equals(<int>{2022, 2023, 2024, 2025, 2026}));
  });
}
