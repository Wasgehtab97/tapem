import 'dart:math' as math;

import 'package:collection/collection.dart';

/// Identifies the type of ledger entry emitted by the XP engine.
enum XpLedgerEventType {
  /// XP that has been earned on an actual training day.
  trainingDay,

  /// Penalty that is triggered once a streak is considered broken.
  streakBreakPenalty,

  /// Penalty that is applied for a full seven day span without any training.
  missedWeekPenalty,
}

/// Represents a single component contributing to an XP delta.
class XpComponent {
  const XpComponent({
    required this.code,
    required this.amount,
    this.metadata = const {},
  });

  /// Machine readable identifier (e.g. `base_daily`, `streak_bonus`).
  final String code;

  /// Signed XP amount the component contributes.
  final int amount;

  /// Optional metadata to facilitate auditing in the ledger.
  final Map<String, Object?> metadata;

  Map<String, Object?> toJson() => {
        'code': code,
        'amount': amount,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };
}

/// A ledger event emitted by the XP engine.
class XpLedgerEvent {
  const XpLedgerEvent({
    required this.type,
    required this.day,
    required this.xpDelta,
    this.components = const <XpComponent>[],
    this.metadata = const <String, Object?>{},
    required this.runningTotalXp,
  });

  /// Kind of event (training, streak break penalty, missed week penalty).
  final XpLedgerEventType type;

  /// Ledger day this event occurred on.
  final LedgerDay day;

  /// Signed XP delta represented by this event.
  final int xpDelta;

  /// Detailed breakdown for XP earning events.
  final List<XpComponent> components;

  /// Additional metadata such as streak length, missed week index, etc.
  final Map<String, Object?> metadata;

  /// XP running total after applying this event (before optional min clamp).
  final int runningTotalXp;
}

/// Canonical representation of a calendar day within a timezone.
class LedgerDay {
  const LedgerDay({
    required this.canonicalDate,
    required this.timeZone,
  }) : assert(canonicalDate.isUtc);

  /// Date truncated to midnight UTC for deterministic ordering.
  final DateTime canonicalDate;

  /// IANA timezone identifier used when normalising the input data.
  final String timeZone;

  /// ISO-8601 date string (YYYY-MM-DD) derived from [canonicalDate].
  String get isoDate {
    final y = canonicalDate.year.toString().padLeft(4, '0');
    final m = canonicalDate.month.toString().padLeft(2, '0');
    final d = canonicalDate.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

/// Configuration for the XP engine with sane business defaults.
class XpEngineConfig {
  const XpEngineConfig({
    this.baseDailyStep = 50,
    this.streakBreakDaysWithoutTraining = 7,
    this.streakBreakPenalty = 50,
    this.missedWeekSpanDays = 7,
    this.missedWeekPenalty = 50,
    this.comebackBonus = 25,
    this.fixedStreakBonuses = const {
      3: 75,
      7: 75,
    },
    this.repeatingStreakBonusStart = 20,
    this.repeatingStreakBonusStep = 10,
    this.repeatingStreakBonusAmount = 75,
    this.trainingDayMilestones = const {
      7: 25,
      30: 75,
      90: 150,
      180: 200,
      270: 200,
      360: 500,
    },
    this.minTotalXp,
  })  : assert(streakBreakDaysWithoutTraining >= 1),
        assert(missedWeekSpanDays >= 1),
        assert(baseDailyStep >= 0);

  /// The XP increment between consecutive training days (default: 50).
  final int baseDailyStep;

  /// Number of consecutive idle days that break a streak (default: 7).
  final int streakBreakDaysWithoutTraining;

  /// Penalty applied when a streak breaks.
  final int streakBreakPenalty;

  /// Length of a missed week window (default: 7 days).
  final int missedWeekSpanDays;

  /// Penalty for each missed week.
  final int missedWeekPenalty;

  /// Bonus applied on the comeback training day.
  final int comebackBonus;

  /// Fixed streak thresholds that award additional XP.
  final Map<int, int> fixedStreakBonuses;

  /// First streak length that receives repeating streak bonuses.
  final int repeatingStreakBonusStart;

  /// Streak step for repeating streak bonuses.
  final int repeatingStreakBonusStep;

  /// XP amount applied for repeating streak bonuses.
  final int repeatingStreakBonusAmount;

  /// Milestones for the cumulative number of training days.
  final Map<int, int> trainingDayMilestones;

  /// Optional lower bound for the final XP total.
  final int? minTotalXp;
}

/// Result object exposing the emitted ledger events and XP totals.
class XpEngineResult {
  const XpEngineResult({
    required this.events,
    required this.computedTotalXp,
    required this.totalXp,
    this.minTotalXp,
  });

  final List<XpLedgerEvent> events;

  /// Sum of all ledger deltas before enforcing [minTotalXp].
  final int computedTotalXp;

  /// Final XP after applying the optional [minTotalXp] clamp.
  final int totalXp;

  final int? minTotalXp;

  bool get minTotalXpApplied =>
      minTotalXp != null && totalXp != computedTotalXp && totalXp == minTotalXp;
}

/// Calculates training day based XP deltas, streaks and penalties.
class TrainingDayXpEngine {
  TrainingDayXpEngine({
    XpEngineConfig config = const XpEngineConfig(),
  }) : _config = config;

  final XpEngineConfig _config;

  /// Builds a deterministic XP ledger for the provided [trainingDays].
  ///
  /// The list should contain calendar days (duplicates allowed) already
  /// expressed in the athlete's local timezone. The [timeZone] identifier is
  /// stored on every ledger event for auditing purposes.
  XpEngineResult buildLedger({
    required Iterable<DateTime> trainingDays,
    required String timeZone,
  }) {
    final normalizedDays = _normalizeTrainingDays(trainingDays, timeZone);

    if (normalizedDays.isEmpty) {
      final computed = 0;
      final minAdjusted = _config.minTotalXp != null
          ? math.max(_config.minTotalXp!, computed)
          : computed;
      return XpEngineResult(
        events: const [],
        computedTotalXp: computed,
        totalXp: minAdjusted,
        minTotalXp: _config.minTotalXp,
      );
    }

    final events = <XpLedgerEvent>[];
    var streak = 0;
    var totalTrainingDays = 0;
    var runningTotal = 0;
    var awaitingComeback = false;
    _NormalizedTrainingDay? previousDay;
    int gapCounter = 0;

    for (final day in normalizedDays) {
      if (previousDay != null) {
        final gapDaysBetween =
            day.canonical.difference(previousDay.canonical).inDays - 1;

        if (gapDaysBetween > 0) {
          gapCounter++;
          runningTotal = _applyGapPenalties(
            events: events,
            previousDay: previousDay,
            gapIndex: gapCounter,
            gapDays: gapDaysBetween,
            runningTotal: runningTotal,
            timeZone: timeZone,
            streakBeforeBreak: streak,
          );
          if (gapDaysBetween >= _config.streakBreakDaysWithoutTraining) {
            awaitingComeback = true;
            streak = 0;
          }
        }
      }

      previousDay = day;
      totalTrainingDays++;
      streak++;

      final components = <XpComponent>[
        XpComponent(
          code: 'base_daily',
          amount: totalTrainingDays * _config.baseDailyStep,
          metadata: {
            'trainingDayIndex': totalTrainingDays,
          },
        ),
      ];

      if (awaitingComeback) {
        components.add(
          XpComponent(
            code: 'comeback_bonus',
            amount: _config.comebackBonus,
          ),
        );
        awaitingComeback = false;
      }

      final streakBonus = _resolveStreakBonus(streak);
      if (streakBonus != null && streakBonus != 0) {
        components.add(
          XpComponent(
            code: 'streak_bonus',
            amount: streakBonus,
            metadata: {
              'streakLength': streak,
            },
          ),
        );
      }

      final milestoneBonus = _config.trainingDayMilestones[totalTrainingDays];
      if (milestoneBonus != null && milestoneBonus != 0) {
        components.add(
          XpComponent(
            code: 'training_day_milestone',
            amount: milestoneBonus,
            metadata: {
              'milestoneDay': totalTrainingDays,
            },
          ),
        );
      }

      final xpDelta = components.map((c) => c.amount).sum;
      runningTotal += xpDelta;

      events.add(
        XpLedgerEvent(
          type: XpLedgerEventType.trainingDay,
          day: day.ledgerDay,
          xpDelta: xpDelta,
          components: List.unmodifiable(components),
          metadata: {
            'trainingDayIndex': totalTrainingDays,
            'streakLength': streak,
          },
          runningTotalXp: runningTotal,
        ),
      );
    }

    final computed = runningTotal;
    final minAdjusted = _config.minTotalXp != null
        ? math.max(_config.minTotalXp!, computed)
        : computed;

    return XpEngineResult(
      events: List.unmodifiable(events),
      computedTotalXp: computed,
      totalXp: minAdjusted,
      minTotalXp: _config.minTotalXp,
    );
  }

  int _applyGapPenalties({
    required List<XpLedgerEvent> events,
    required _NormalizedTrainingDay previousDay,
    required int gapIndex,
    required int gapDays,
    required int runningTotal,
    required String timeZone,
    required int streakBeforeBreak,
  }) {
    final missableWeeks = gapDays ~/ _config.missedWeekSpanDays;

    if (gapDays >= _config.streakBreakDaysWithoutTraining) {
      final breakEventDay = _dateFromCanonical(
        timeZone,
        previousDay.canonical.add(
          Duration(days: _config.streakBreakDaysWithoutTraining),
        ),
      );
      final delta = -_config.streakBreakPenalty;
      runningTotal += delta;
      events.add(
        XpLedgerEvent(
          type: XpLedgerEventType.streakBreakPenalty,
          day: breakEventDay,
          xpDelta: delta,
          metadata: {
            'gapIndex': gapIndex,
            'idleDays': gapDays,
            'streakBeforeBreak': streakBeforeBreak,
          },
          runningTotalXp: runningTotal,
        ),
      );
    }

    for (var week = 1; week <= missableWeeks; week++) {
      final penaltyDay = _dateFromCanonical(
        timeZone,
        previousDay.canonical.add(
          Duration(days: week * _config.missedWeekSpanDays),
        ),
      );
      final delta = -_config.missedWeekPenalty;
      runningTotal += delta;
      events.add(
        XpLedgerEvent(
          type: XpLedgerEventType.missedWeekPenalty,
          day: penaltyDay,
          xpDelta: delta,
          metadata: {
            'gapIndex': gapIndex,
            'idleDays': gapDays,
            'missedWeekNumber': week,
          },
          runningTotalXp: runningTotal,
        ),
      );
    }

    return runningTotal;
  }

  int? _resolveStreakBonus(int streak) {
    final fixed = _config.fixedStreakBonuses[streak];
    if (fixed != null) {
      return fixed;
    }

    if (_config.repeatingStreakBonusStep <= 0) {
      return null;
    }

    if (streak >= _config.repeatingStreakBonusStart) {
      final distance = streak - _config.repeatingStreakBonusStart;
      if (distance % _config.repeatingStreakBonusStep == 0) {
        return _config.repeatingStreakBonusAmount;
      }
    }

    return null;
  }

  List<_NormalizedTrainingDay> _normalizeTrainingDays(
    Iterable<DateTime> days,
    String timeZone,
  ) {
    final unique = <DateTime, _NormalizedTrainingDay>{};
    for (final raw in days) {
      final canonical = DateTime.utc(raw.year, raw.month, raw.day);
      unique.putIfAbsent(
        canonical,
        () => _NormalizedTrainingDay(
          ledgerDay: LedgerDay(
            canonicalDate: canonical,
            timeZone: timeZone,
          ),
          canonical: canonical,
        ),
      );
    }
    final days = unique.values.toList()
      ..sort((a, b) => a.canonical.compareTo(b.canonical));
    return days;
  }

  LedgerDay _dateFromCanonical(String timeZone, DateTime canonical) {
    return LedgerDay(canonicalDate: canonical, timeZone: timeZone);
  }
}

class _NormalizedTrainingDay {
  const _NormalizedTrainingDay({
    required this.ledgerDay,
    required this.canonical,
  });

  final LedgerDay ledgerDay;
  final DateTime canonical;
}
