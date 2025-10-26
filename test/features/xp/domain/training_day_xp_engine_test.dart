import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/xp/domain/training_day_xp_engine.dart';

void main() {
  group('TrainingDayXpEngine gap penalty clamping', () {
    test('maintains zero XP when penalties exceed available XP', () {
      final engine = TrainingDayXpEngine(
        config: const XpEngineConfig(
          baseDailyStep: 0,
          streakBreakDaysWithoutTraining: 7,
          streakBreakPenalty: 50,
          missedWeekSpanDays: 7,
          missedWeekPenalty: 50,
          comebackBonus: 25,
          fixedStreakBonuses: {},
          trainingDayMilestones: {},
          minTotalXp: 0,
        ),
      );

      final ledger = engine.buildLedger(
        trainingDays: [
          DateTime.utc(2024, 1, 1),
          DateTime.utc(2024, 4, 1),
        ],
        timeZone: 'UTC',
      );

      final penaltyEvents = ledger.events
          .where((event) => event.type != XpLedgerEventType.trainingDay)
          .toList();
      final trainingEvents = ledger.events
          .where((event) => event.type == XpLedgerEventType.trainingDay)
          .toList();

      expect(penaltyEvents, isNotEmpty);
      expect(penaltyEvents.every((event) => event.xpDelta == 0), isTrue);
      expect(penaltyEvents.every((event) => event.runningTotalXp == 0), isTrue);

      expect(trainingEvents.length, 2);
      expect(trainingEvents.first.xpDelta, 0);
      expect(trainingEvents.first.runningTotalXp, 0);
      expect(trainingEvents.last.xpDelta, 25);
      expect(trainingEvents.last.runningTotalXp, 25);

      expect(ledger.totalXp, 25);
      expect(ledger.computedTotalXp, 25);
    });

    test('caps penalties when XP is limited before a comeback day', () {
      final engine = TrainingDayXpEngine(
        config: const XpEngineConfig(
          baseDailyStep: 30,
          streakBreakDaysWithoutTraining: 7,
          streakBreakPenalty: 50,
          missedWeekSpanDays: 7,
          missedWeekPenalty: 50,
          comebackBonus: 25,
          fixedStreakBonuses: {},
          trainingDayMilestones: {},
          minTotalXp: 0,
        ),
      );

      final ledger = engine.buildLedger(
        trainingDays: [
          DateTime.utc(2024, 1, 1),
          DateTime.utc(2024, 2, 20),
        ],
        timeZone: 'UTC',
      );

      final penaltyEvents = ledger.events
          .where((event) => event.type != XpLedgerEventType.trainingDay)
          .toList();
      final streakBreak = penaltyEvents.firstWhere(
        (event) => event.type == XpLedgerEventType.streakBreakPenalty,
      );
      final missedWeeks = penaltyEvents
          .where((event) => event.type == XpLedgerEventType.missedWeekPenalty)
          .toList();
      final trainingEvents = ledger.events
          .where((event) => event.type == XpLedgerEventType.trainingDay)
          .toList();

      expect(streakBreak.xpDelta, -30);
      expect(streakBreak.runningTotalXp, 0);
      expect(missedWeeks, isNotEmpty);
      expect(missedWeeks.every((event) => event.xpDelta == 0), isTrue);
      expect(missedWeeks.every((event) => event.runningTotalXp == 0), isTrue);

      expect(trainingEvents.length, 2);
      expect(trainingEvents.last.xpDelta, 85);
      expect(trainingEvents.last.runningTotalXp, 85);

      expect(ledger.totalXp, 85);
      expect(ledger.computedTotalXp, 85);
    });
  });
}
