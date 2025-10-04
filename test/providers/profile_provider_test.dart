import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/core/providers/profile_provider.dart';

void main() {
  group('ProfileProvider._calculateAverageTrainingDaysPerWeek', () {
    test('ignores ongoing week when calculating average', () {
      final provider = ProfileProvider();
      final now = DateTime(2024, 4, 10); // Wednesday

      provider.setTrainingDayDatesForTest([
        DateTime(2024, 4, 1),
        DateTime(2024, 4, 3),
        DateTime(2024, 4, 9), // current week, should be ignored
      ]);

      final average = provider.calculateAverageTrainingDaysPerWeekForTest(
        DateTime(2024, 3, 28),
        nowProvider: () => now,
      );

      expect(average, closeTo(2.0, 1e-9));
    });

    test('counts weeks with a single training day correctly', () {
      final provider = ProfileProvider();
      final now = DateTime(2024, 3, 25); // Monday

      provider.setTrainingDayDatesForTest([
        DateTime(2024, 3, 12), // before first Monday, ignored
        DateTime(2024, 3, 19),
      ]);

      final average = provider.calculateAverageTrainingDaysPerWeekForTest(
        DateTime(2024, 3, 11),
        nowProvider: () => now,
      );

      expect(average, closeTo(1.0, 1e-9));
    });

    test('averages across multiple completed weeks', () {
      final provider = ProfileProvider();
      final now = DateTime(2024, 3, 27); // Wednesday

      provider.setTrainingDayDatesForTest([
        DateTime(2024, 3, 12),
        DateTime(2024, 3, 14),
        DateTime(2024, 3, 19),
      ]);

      final average = provider.calculateAverageTrainingDaysPerWeekForTest(
        DateTime(2024, 3, 9),
        nowProvider: () => now,
      );

      expect(average, closeTo(1.5, 1e-9));
    });

    test('returns zero when there is no completed week', () {
      final provider = ProfileProvider();
      final now = DateTime(2024, 4, 17); // Wednesday

      provider.setTrainingDayDatesForTest([
        DateTime(2024, 4, 12),
        DateTime(2024, 4, 14),
      ]);

      final average = provider.calculateAverageTrainingDaysPerWeekForTest(
        DateTime(2024, 4, 10),
        nowProvider: () => now,
      );

      expect(average, 0);
    });
  });
}
