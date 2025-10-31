import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/device/domain/utils/e1rm_utils.dart';

void main() {
  group('calculateEpleyOneRepMax', () {
    test('returns expected value for valid input', () {
      final result = calculateEpleyOneRepMax(weightKg: 100, reps: 5);
      expect(result, closeTo(116.67, 0.01));
    });

    test('returns null for non-positive inputs', () {
      expect(calculateEpleyOneRepMax(weightKg: 0, reps: 5), isNull);
      expect(calculateEpleyOneRepMax(weightKg: 100, reps: 0), isNull);
      expect(calculateEpleyOneRepMax(weightKg: -50, reps: 5), isNull);
    });

    test('returns null when weight or reps is null', () {
      expect(calculateEpleyOneRepMax(weightKg: null, reps: 5), isNull);
      expect(calculateEpleyOneRepMax(weightKg: 80, reps: null), isNull);
    });
  });
}
