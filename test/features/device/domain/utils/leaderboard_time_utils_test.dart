import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/device/domain/utils/leaderboard_time_utils.dart';

void main() {
  group('resolveTimeRangeUtc', () {
    final reference = DateTime(2024, 1, 18, 12, 0);

    test('computes today range', () {
      final range = resolveTimeRangeUtc(LeaderboardPeriod.today, reference: reference);
      final localStart = range.startUtc.toLocal();
      final localEnd = range.endUtc.toLocal();
      expect(localStart.year, reference.year);
      expect(localStart.month, reference.month);
      expect(localStart.day, reference.day);
      expect(localStart.hour, 0);
      expect(localStart.minute, 0);
      expect(localEnd.difference(range.startUtc).inHours, 24);
    });

    test('computes week range starting on Monday', () {
      final range = resolveTimeRangeUtc(LeaderboardPeriod.week, reference: reference);
      final localStart = range.startUtc.toLocal();
      expect(localStart.weekday, DateTime.monday);
      expect(range.endUtc.difference(range.startUtc).inDays, 7);
    });

    test('computes month range', () {
      final range = resolveTimeRangeUtc(LeaderboardPeriod.month, reference: reference);
      final localStart = range.startUtc.toLocal();
      expect(localStart.day, 1);
      expect(localStart.month, reference.month);
      expect(range.endUtc.toLocal().month, reference.month + 1);
    });
  });
}
