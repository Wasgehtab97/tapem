import 'dart:math' as math;

import 'package:equatable/equatable.dart';

enum TrainingPlanScheduleMode { weekly, everyXDays }

class TrainingPlanSchedule extends Equatable {
  const TrainingPlanSchedule({
    this.enabled = false,
    this.mode = TrainingPlanScheduleMode.weekly,
    this.weekdays = const <int>[1],
    this.intervalDays = 2,
    this.anchorDate,
  });

  const TrainingPlanSchedule.disabled()
    : enabled = false,
      mode = TrainingPlanScheduleMode.weekly,
      weekdays = const <int>[1],
      intervalDays = 2,
      anchorDate = null;

  final bool enabled;
  final TrainingPlanScheduleMode mode;
  final List<int> weekdays; // DateTime.weekday: 1=Mon ... 7=Sun
  final int intervalDays;
  final DateTime? anchorDate;

  TrainingPlanSchedule copyWith({
    bool? enabled,
    TrainingPlanScheduleMode? mode,
    List<int>? weekdays,
    int? intervalDays,
    DateTime? anchorDate,
    bool clearAnchorDate = false,
  }) {
    return TrainingPlanSchedule(
      enabled: enabled ?? this.enabled,
      mode: mode ?? this.mode,
      weekdays: _normalizeWeekdays(weekdays ?? this.weekdays),
      intervalDays: _normalizeInterval(intervalDays ?? this.intervalDays),
      anchorDate: clearAnchorDate
          ? null
          : _normalizeDate(anchorDate ?? this.anchorDate),
    );
  }

  bool matchesDate(DateTime date) {
    if (!enabled) return false;
    final normalizedDate = _normalizeDate(date)!;
    switch (mode) {
      case TrainingPlanScheduleMode.weekly:
        final validDays = _normalizeWeekdays(weekdays);
        if (validDays.isEmpty) return false;
        return validDays.contains(normalizedDate.weekday);
      case TrainingPlanScheduleMode.everyXDays:
        final anchor = _normalizeDate(anchorDate);
        if (anchor == null) return false;
        final deltaDays = normalizedDate.difference(anchor).inDays;
        if (deltaDays < 0) return false;
        final step = _normalizeInterval(intervalDays);
        return deltaDays % step == 0;
    }
  }

  factory TrainingPlanSchedule.fromJson(Map<String, dynamic> json) {
    final modeRaw = (json['mode'] ?? '').toString();
    final mode = modeRaw == 'everyXDays'
        ? TrainingPlanScheduleMode.everyXDays
        : TrainingPlanScheduleMode.weekly;

    final weekdaysRaw = json['weekdays'];
    final weekdays = <int>[];
    if (weekdaysRaw is List) {
      for (final entry in weekdaysRaw) {
        if (entry is int) {
          weekdays.add(entry);
          continue;
        }
        if (entry is num) {
          weekdays.add(entry.toInt());
          continue;
        }
        if (entry is String) {
          final parsed = int.tryParse(entry.trim());
          if (parsed != null) {
            weekdays.add(parsed);
          }
        }
      }
    }

    final intervalRaw = json['intervalDays'];
    int intervalDays = 2;
    if (intervalRaw is int) {
      intervalDays = intervalRaw;
    } else if (intervalRaw is num) {
      intervalDays = intervalRaw.toInt();
    } else if (intervalRaw is String) {
      final parsed = int.tryParse(intervalRaw.trim());
      if (parsed != null) {
        intervalDays = parsed;
      }
    }

    DateTime? anchorDate;
    final anchorRaw = json['anchorDate'];
    if (anchorRaw is String && anchorRaw.trim().isNotEmpty) {
      anchorDate = DateTime.tryParse(anchorRaw.trim());
    } else if (anchorRaw is DateTime) {
      anchorDate = anchorRaw;
    } else if (anchorRaw is int) {
      anchorDate = DateTime.fromMillisecondsSinceEpoch(anchorRaw);
    } else if (anchorRaw is num) {
      anchorDate = DateTime.fromMillisecondsSinceEpoch(anchorRaw.toInt());
    }

    final enabledRaw = json['enabled'];
    final enabled =
        enabledRaw == true ||
        (enabledRaw is String && enabledRaw.toLowerCase() == 'true');

    return TrainingPlanSchedule(
      enabled: enabled,
      mode: mode,
      weekdays: _normalizeWeekdays(weekdays),
      intervalDays: _normalizeInterval(intervalDays),
      anchorDate: _normalizeDate(anchorDate),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'mode': mode == TrainingPlanScheduleMode.everyXDays
          ? 'everyXDays'
          : 'weekly',
      'weekdays': _normalizeWeekdays(weekdays),
      'intervalDays': _normalizeInterval(intervalDays),
      if (anchorDate != null)
        'anchorDate': _normalizeDate(anchorDate)!.toIso8601String(),
    };
  }

  static List<int> _normalizeWeekdays(List<int> source) {
    final distinct = source.toSet().toList()..sort();
    final filtered = distinct.where((day) => day >= 1 && day <= 7).toList();
    if (filtered.isEmpty) {
      return const <int>[1];
    }
    return filtered;
  }

  static int _normalizeInterval(int value) {
    return math.max(1, value);
  }

  static DateTime? _normalizeDate(DateTime? date) {
    if (date == null) return null;
    return DateTime(date.year, date.month, date.day);
  }

  @override
  List<Object?> get props => [
    enabled,
    mode,
    weekdays,
    intervalDays,
    anchorDate,
  ];
}
