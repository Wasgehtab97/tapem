import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_weight_year_summary.dart';

void main() {
  test('parses nested day payloads with non-dynamic map values', () {
    final data = <String, dynamic>{
      'days': <String, Object?>{
        '20260306': <String, Object?>{'kg': 82.4},
      },
    };

    final summary = NutritionWeightYearSummary.fromMap(2026, data);
    expect(summary.days['20260306']?.kg, closeTo(82.4, 0.0001));
  });

  test('parses legacy root-level date keys', () {
    final data = <String, dynamic>{
      '20260305': <String, Object?>{'kg': 81.9},
      '20260306': 82.4,
      'ignoredField': 'legacy',
    };

    final summary = NutritionWeightYearSummary.fromMap(2026, data);
    expect(summary.days.keys, containsAll(<String>['20260305', '20260306']));
    expect(summary.days['20260305']?.kg, closeTo(81.9, 0.0001));
    expect(summary.days['20260306']?.kg, closeTo(82.4, 0.0001));
  });
}
