import 'package:flutter_test/flutter_test.dart';

import 'package:tapem/features/community/presentation/providers/community_providers.dart';

void main() {
  group('periodToUtcRange', () {
    Duration _dstForwardResolver(DateTime date) {
      final pivot = DateTime(2024, 3, 31);
      return date.isBefore(pivot) ? const Duration(hours: 1) : const Duration(hours: 2);
    }

    Duration _dstBackwardResolver(DateTime date) {
      final pivot = DateTime(2024, 10, 27);
      return date.isBefore(pivot) ? const Duration(hours: 2) : const Duration(hours: 1);
    }

    test('computes UTC range for day across DST forward transition', () {
      final range = periodToUtcRange(
        CommunityPeriod.today,
        now: DateTime(2024, 3, 31, 10),
        offsetResolver: _dstForwardResolver,
      );

      expect(range.start, DateTime.utc(2024, 3, 30, 23));
      expect(range.end, DateTime.utc(2024, 3, 31, 22));
    });

    test('computes UTC range for week spanning DST forward transition', () {
      final range = periodToUtcRange(
        CommunityPeriod.week,
        now: DateTime(2024, 3, 31, 10),
        offsetResolver: _dstForwardResolver,
      );

      expect(range.start, DateTime.utc(2024, 3, 24, 23));
      expect(range.end, DateTime.utc(2024, 3, 31, 22));
    });

    test('computes UTC range for day across DST backward transition', () {
      final range = periodToUtcRange(
        CommunityPeriod.today,
        now: DateTime(2024, 10, 27, 9),
        offsetResolver: _dstBackwardResolver,
      );

      expect(range.start, DateTime.utc(2024, 10, 26, 22));
      expect(range.end, DateTime.utc(2024, 10, 27, 23));
    });

    test('computes UTC range for month across DST backward transition', () {
      final range = periodToUtcRange(
        CommunityPeriod.month,
        now: DateTime(2024, 10, 27, 9),
        offsetResolver: _dstBackwardResolver,
      );

      expect(range.start, DateTime.utc(2024, 9, 30, 22));
      expect(range.end, DateTime.utc(2024, 10, 31, 23));
    });
  });
}
