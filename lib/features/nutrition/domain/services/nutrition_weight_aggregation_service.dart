import 'package:tapem/features/nutrition/domain/models/nutrition_weight_bucket.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_weight_range.dart';

class NutritionWeightAggregationService {
  const NutritionWeightAggregationService();

  Set<int> requiredYearsForRange({
    required NutritionWeightRange range,
    required DateTime referenceDate,
    int? bucketCount,
  }) {
    final ref = _startOfDay(referenceDate);
    final count = (bucketCount ?? range.defaultBucketCount).clamp(1, 120);
    final specs = _buildBucketSpecs(
      range: range,
      referenceDate: ref,
      count: count,
    );
    if (specs.isEmpty) return {ref.year};
    final years = <int>{};
    for (final spec in specs) {
      for (var y = spec.start.year; y <= spec.end.year; y++) {
        years.add(y);
      }
    }
    return years;
  }

  List<NutritionWeightBucket> aggregateAverages({
    required Map<String, double> dailyWeights,
    required NutritionWeightRange range,
    required DateTime referenceDate,
    int? bucketCount,
    bool includeEmptyBuckets = false,
  }) {
    if (dailyWeights.isEmpty) return const [];
    final ref = _startOfDay(referenceDate);
    final count = (bucketCount ?? range.defaultBucketCount).clamp(1, 120);
    final specs = _buildBucketSpecs(
      range: range,
      referenceDate: ref,
      count: count,
    );
    if (specs.isEmpty) return const [];

    final parsed = <DateTime, double>{};
    for (final entry in dailyWeights.entries) {
      final date = _parseDateKey(entry.key);
      final value = entry.value;
      if (date == null || !value.isFinite) continue;
      parsed[date] = value;
    }
    if (parsed.isEmpty) return const [];

    final buckets = <NutritionWeightBucket>[];
    for (final spec in specs) {
      var sum = 0.0;
      var countSamples = 0;
      for (final entry in parsed.entries) {
        if (_isWithin(entry.key, spec.start, spec.end)) {
          sum += entry.value;
          countSamples++;
        }
      }
      if (!includeEmptyBuckets && countSamples == 0) continue;
      final avg = countSamples == 0 ? 0.0 : _round2(sum / countSamples);
      buckets.add(
        NutritionWeightBucket(
          id: spec.id,
          start: spec.start,
          end: spec.end,
          label: spec.label,
          avgKg: avg,
          sampleCount: countSamples,
        ),
      );
    }
    return buckets;
  }

  List<_WeightBucketSpec> _buildBucketSpecs({
    required NutritionWeightRange range,
    required DateTime referenceDate,
    required int count,
  }) {
    switch (range) {
      case NutritionWeightRange.week:
        return _buildWeekSpecs(referenceDate, count);
      case NutritionWeightRange.month:
        return _buildMonthSpecs(referenceDate, count);
      case NutritionWeightRange.quarter:
        return _buildQuarterSpecs(referenceDate, count);
      case NutritionWeightRange.year:
        return _buildYearSpecs(referenceDate, count);
    }
  }

  List<_WeightBucketSpec> _buildWeekSpecs(DateTime referenceDate, int count) {
    final currentWeekStart = _startOfIsoWeek(referenceDate);
    final specs = <_WeightBucketSpec>[];
    for (var i = count - 1; i >= 0; i--) {
      final start = currentWeekStart.subtract(Duration(days: i * 7));
      final end = start.add(const Duration(days: 6));
      final iso = _isoWeek(start);
      final weekLabel = iso.week.toString().padLeft(2, '0');
      specs.add(
        _WeightBucketSpec(
          id: '${iso.year}-W$weekLabel',
          start: start,
          end: end,
          label: 'KW $weekLabel ${iso.year}',
        ),
      );
    }
    return specs;
  }

  List<_WeightBucketSpec> _buildMonthSpecs(DateTime referenceDate, int count) {
    final monthStart = DateTime(referenceDate.year, referenceDate.month, 1);
    final specs = <_WeightBucketSpec>[];
    for (var i = count - 1; i >= 0; i--) {
      final start = DateTime(monthStart.year, monthStart.month - i, 1);
      final end = DateTime(start.year, start.month + 1, 0);
      final monthLabel = start.month.toString().padLeft(2, '0');
      specs.add(
        _WeightBucketSpec(
          id: '${start.year}-$monthLabel',
          start: start,
          end: end,
          label: '$monthLabel/${start.year}',
        ),
      );
    }
    return specs;
  }

  List<_WeightBucketSpec> _buildQuarterSpecs(
    DateTime referenceDate,
    int count,
  ) {
    final quarterStartMonth = (((referenceDate.month - 1) ~/ 3) * 3) + 1;
    final quarterStart = DateTime(referenceDate.year, quarterStartMonth, 1);
    final specs = <_WeightBucketSpec>[];
    for (var i = count - 1; i >= 0; i--) {
      final start = DateTime(
        quarterStart.year,
        quarterStart.month - (i * 3),
        1,
      );
      final end = DateTime(start.year, start.month + 3, 0);
      final quarter = ((start.month - 1) ~/ 3) + 1;
      specs.add(
        _WeightBucketSpec(
          id: '${start.year}-Q$quarter',
          start: start,
          end: end,
          label: 'Q$quarter ${start.year}',
        ),
      );
    }
    return specs;
  }

  List<_WeightBucketSpec> _buildYearSpecs(DateTime referenceDate, int count) {
    final yearStart = DateTime(referenceDate.year, 1, 1);
    final specs = <_WeightBucketSpec>[];
    for (var i = count - 1; i >= 0; i--) {
      final start = DateTime(yearStart.year - i, 1, 1);
      final end = DateTime(start.year, 12, 31);
      specs.add(
        _WeightBucketSpec(
          id: '${start.year}',
          start: start,
          end: end,
          label: '${start.year}',
        ),
      );
    }
    return specs;
  }

  DateTime? _parseDateKey(String key) {
    if (key.length != 8) return null;
    final year = int.tryParse(key.substring(0, 4));
    final month = int.tryParse(key.substring(4, 6));
    final day = int.tryParse(key.substring(6, 8));
    if (year == null || month == null || day == null) return null;
    final parsed = DateTime(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      return null;
    }
    return _startOfDay(parsed);
  }

  DateTime _startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  DateTime _startOfIsoWeek(DateTime date) {
    final d = _startOfDay(date);
    final diff = d.weekday - DateTime.monday;
    return d.subtract(Duration(days: diff));
  }

  _IsoWeek _isoWeek(DateTime date) {
    final normalized = _startOfDay(date);
    final thursday = normalized.add(Duration(days: 4 - normalized.weekday));
    final firstThursday = DateTime(thursday.year, 1, 4);
    final startOfWeek1 = firstThursday.subtract(
      Duration(days: firstThursday.weekday - 1),
    );
    final week = ((thursday.difference(startOfWeek1).inDays) ~/ 7) + 1;
    return _IsoWeek(year: thursday.year, week: week);
  }

  bool _isWithin(DateTime date, DateTime start, DateTime end) {
    return !date.isBefore(start) && !date.isAfter(end);
  }

  double _round2(double value) => double.parse(value.toStringAsFixed(2));
}

class _WeightBucketSpec {
  final String id;
  final DateTime start;
  final DateTime end;
  final String label;

  const _WeightBucketSpec({
    required this.id,
    required this.start,
    required this.end,
    required this.label,
  });
}

class _IsoWeek {
  final int year;
  final int week;

  const _IsoWeek({required this.year, required this.week});
}
