import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:tapem/features/xp/domain/training_day_xp_engine.dart';

void main() {
  const timeZone = 'Europe/Berlin';

  TrainingDayXpEngine createEngine({XpEngineConfig config = const XpEngineConfig()}) {
    return TrainingDayXpEngine(config: config);
  }

  group('TrainingDayXpEngine', () {
    test('returns empty ledger when no training days are provided', () {
      final result = createEngine().buildLedger(
        trainingDays: const [],
        timeZone: timeZone,
      );

      expect(result.events, isEmpty);
      expect(result.computedTotalXp, 0);
      expect(result.totalXp, 0);
    });

    test('deduplicates multiple entries for the same day and unsorted input', () {
      final days = [
        DateTime.utc(2024, 3, 10),
        DateTime.utc(2024, 3, 10, 12),
        DateTime.utc(2024, 3, 9, 23, 59),
        DateTime.utc(2024, 3, 12),
      ];

      final result = createEngine().buildLedger(
        trainingDays: days.reversed,
        timeZone: timeZone,
      );

      final trainingEvents = result.events
          .where((event) => event.type == XpLedgerEventType.trainingDay)
          .toList();

      expect(trainingEvents, hasLength(3));
      expect(
        trainingEvents.map((event) => event.day.isoDate).toList(),
        ['2024-03-09', '2024-03-10', '2024-03-12'],
      );
      final thirdDay = trainingEvents.last;
      expect(
        thirdDay.components
            .firstWhere((component) => component.code == 'streak_bonus')
            .amount,
        75,
      );
      expect(result.computedTotalXp, 50 + 100 + 150 + 75);
    });

    test('streak breaks after seven idle days but not after six', () {
      final days = [
        DateTime.utc(2024, 1, 1),
        DateTime.utc(2024, 1, 8),
        DateTime.utc(2024, 1, 16),
      ];

      final result = createEngine().buildLedger(
        trainingDays: days,
        timeZone: timeZone,
      );

      final breakEvents = result.events
          .where((event) => event.type == XpLedgerEventType.streakBreakPenalty)
          .toList();
      final missedWeeks = result.events
          .where((event) => event.type == XpLedgerEventType.missedWeekPenalty)
          .toList();

      expect(breakEvents, hasLength(1));
      expect(breakEvents.first.day.isoDate, '2024-01-15');

      expect(missedWeeks, hasLength(1));
      expect(missedWeeks.first.day.isoDate, '2024-01-15');

      final comebackDay = result.events
          .where((event) => event.type == XpLedgerEventType.trainingDay)
          .last;
      expect(
        comebackDay.components.map((component) => component.code),
        contains('comeback_bonus'),
      );
      expect(
        comebackDay.components
            .firstWhere((component) => component.code == 'comeback_bonus')
            .amount,
        25,
      );
    });

    test('missed week penalties handle gaps of 1, 2 and 3 weeks', () {
      final result = createEngine().buildLedger(
        trainingDays: [
          DateTime.utc(2024, 2, 1),
          DateTime.utc(2024, 2, 9),
          DateTime.utc(2024, 2, 24),
          DateTime.utc(2024, 3, 17),
        ],
        timeZone: timeZone,
      );

      final penalties = result.events
          .where((event) => event.type == XpLedgerEventType.missedWeekPenalty)
          .map((event) => event.day.isoDate)
          .toList();

      expect(penalties, [
        '2024-02-08',
        '2024-02-16',
        '2024-02-23',
        '2024-03-02',
        '2024-03-09',
        '2024-03-16',
      ]);
    });

    test('streak threshold bonuses stack with milestone bonuses', () {
      final days = List<DateTime>.generate(
        7,
        (index) => DateTime.utc(2024, 4, index + 1),
      );

      final result = createEngine().buildLedger(
        trainingDays: days,
        timeZone: timeZone,
      );

      final day7 = result.events
          .where((event) => event.type == XpLedgerEventType.trainingDay)
          .firstWhere((event) => event.metadata['trainingDayIndex'] == 7);

      final bonus = day7.components
          .where((component) => component.code != 'base_daily')
          .fold<int>(0, (sum, component) => sum + component.amount);

      expect(bonus, 100); // 75 streak + 25 milestone
      expect(day7.xpDelta, 350 + 100);
    });

    test('handles DST transition around Europe/Berlin spring forward', () {
      final result = createEngine().buildLedger(
        trainingDays: [
          DateTime.utc(2024, 3, 30),
          DateTime.utc(2024, 3, 31),
          DateTime.utc(2024, 4, 1),
        ],
        timeZone: timeZone,
      );

      final streaks = result.events
          .where((event) => event.type == XpLedgerEventType.trainingDay)
          .map((event) => event.metadata['streakLength'])
          .toList();

      expect(streaks, [1, 2, 3]);
      expect(
        result.events.where((event) => event.type != XpLedgerEventType.trainingDay),
        isEmpty,
      );
    });

    test('applies optional minTotalXp clamp without mutating ledger deltas', () {
      final config = const XpEngineConfig(minTotalXp: 0);
      final result = createEngine(config: config).buildLedger(
        trainingDays: [
          DateTime.utc(2024, 1, 1),
          DateTime.utc(2024, 6, 1),
        ],
        timeZone: timeZone,
      );

      expect(result.computedTotalXp, lessThan(0));
      expect(result.totalXp, 0);
      expect(result.minTotalXpApplied, isTrue);
    });

    test('produces deterministic ledger for shuffled input', () {
      final original = [
        DateTime.utc(2023, 12, 20),
        DateTime.utc(2023, 12, 22),
        DateTime.utc(2024, 1, 10),
        DateTime.utc(2024, 1, 25),
        DateTime.utc(2024, 2, 5),
        DateTime.utc(2024, 3, 20),
        DateTime.utc(2024, 3, 21),
        DateTime.utc(2024, 4, 1),
      ];

      final shuffled = List<DateTime>.from(original)..shuffle(Random(1));

      final resultA = createEngine().buildLedger(
        trainingDays: original,
        timeZone: timeZone,
      );
      final resultB = createEngine().buildLedger(
        trainingDays: shuffled,
        timeZone: timeZone,
      );

      expect(resultA.computedTotalXp, resultB.computedTotalXp);
      expect(resultA.events.length, resultB.events.length);

      for (var i = 0; i < resultA.events.length; i++) {
        final a = resultA.events[i];
        final b = resultB.events[i];
        expect(a.type, b.type);
        expect(a.day.isoDate, b.day.isoDate);
        expect(a.xpDelta, b.xpDelta);
      }
    });
  });
}
