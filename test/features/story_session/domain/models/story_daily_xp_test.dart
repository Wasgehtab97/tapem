import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/story_session/domain/models/story_daily_xp.dart';

void main() {
  group('StoryDailyXp helpers', () {
    test('compute positive net change with penalties', () {
      const penalties = [
        StoryXpPenalty(
          id: 'p1',
          type: 'streakBreakPenalty',
          delta: -20,
          day: '2024-01-02',
        ),
      ];
      const dailyXp = StoryDailyXp(
        xp: 150,
        totalXp: 1120,
        computedTotalXp: 1120,
        runningTotalXp: 1120,
        penalties: penalties,
      );

      expect(dailyXp.penaltySum, -20);
      expect(dailyXp.previousTotalXp, 990);
      expect(dailyXp.netXpDelta, 130);
      expect(dailyXp.floorApplied, isFalse);
    });

    test('handle zero change without penalties', () {
      const dailyXp = StoryDailyXp(
        xp: 0,
        totalXp: 500,
        computedTotalXp: 500,
        runningTotalXp: 500,
      );

      expect(dailyXp.penaltySum, 0);
      expect(dailyXp.previousTotalXp, 500);
      expect(dailyXp.netXpDelta, 0);
      expect(dailyXp.floorApplied, isFalse);
    });

    test('detect floor application for negative ledger result', () {
      const penalties = [
        StoryXpPenalty(
          id: 'p2',
          type: 'missedWeekPenalty',
          delta: -120,
          day: '2024-01-09',
        ),
      ];
      const dailyXp = StoryDailyXp(
        xp: 50,
        totalXp: 0,
        computedTotalXp: -70,
        runningTotalXp: -70,
        penalties: penalties,
      );

      expect(dailyXp.penaltySum, -120);
      expect(dailyXp.previousTotalXp, 0);
      expect(dailyXp.netXpDelta, 0);
      expect(dailyXp.floorApplied, isTrue);
    });
  });
}
