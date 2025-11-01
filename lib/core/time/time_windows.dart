/// Resolves the timezone offset (local -> UTC) for a given local midnight.
typedef TimeZoneOffsetResolver = Duration Function(DateTime localDate);

/// Represents a half-open time window `[startUtc, endUtc)` in UTC.
class TimeWindow {
  const TimeWindow({required this.startUtc, required this.endUtc})
      : assert(!startUtc.isUtc || !endUtc.isUtc || !startUtc.isAfter(endUtc));

  final DateTime startUtc;
  final DateTime endUtc;

  bool get isValid => !startUtc.isAfter(endUtc);

  @override
  String toString() => 'TimeWindow(startUtc: ' '$startUtc, endUtc: $endUtc)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimeWindow &&
        other.startUtc == startUtc &&
        other.endUtc == endUtc;
  }

  @override
  int get hashCode => Object.hash(startUtc, endUtc);
}

Duration _resolveOffset(
  DateTime date,
  TimeZoneOffsetResolver? resolver,
) {
  if (resolver != null) {
    return resolver(date);
  }
  return date.timeZoneOffset;
}

DateTime _midnightUtc(
  DateTime localDate,
  TimeZoneOffsetResolver? resolver,
) {
  final normalized = DateTime(localDate.year, localDate.month, localDate.day);
  final offset = _resolveOffset(normalized, resolver);
  final utcMidnight =
      DateTime.utc(normalized.year, normalized.month, normalized.day);
  final converted = utcMidnight.subtract(offset);
  return DateTime.utc(
    converted.year,
    converted.month,
    converted.day,
    converted.hour,
    converted.minute,
    converted.second,
    converted.millisecond,
    converted.microsecond,
  );
}

/// Returns the UTC range for the current local day.
TimeWindow todayUtcRange(
  DateTime now, {
  TimeZoneOffsetResolver? offsetResolver,
}) {
  final startLocal = DateTime(now.year, now.month, now.day);
  final endLocal = startLocal.add(const Duration(days: 1));
  return TimeWindow(
    startUtc: _midnightUtc(startLocal, offsetResolver),
    endUtc: _midnightUtc(endLocal, offsetResolver),
  );
}

/// Returns the UTC range for the ISO week (Mon-Sun) of [now].
TimeWindow weekUtcRange(
  DateTime now, {
  TimeZoneOffsetResolver? offsetResolver,
}) {
  final startLocal = DateTime(now.year, now.month, now.day)
      .subtract(Duration(days: now.weekday - DateTime.monday));
  final endLocal = startLocal.add(const Duration(days: 7));
  return TimeWindow(
    startUtc: _midnightUtc(startLocal, offsetResolver),
    endUtc: _midnightUtc(endLocal, offsetResolver),
  );
}

/// Returns the UTC range for the calendar month of [now].
TimeWindow monthUtcRange(
  DateTime now, {
  TimeZoneOffsetResolver? offsetResolver,
}) {
  final startLocal = DateTime(now.year, now.month, 1);
  final endLocal = (now.month < DateTime.december)
      ? DateTime(now.year, now.month + 1, 1)
      : DateTime(now.year + 1, DateTime.january, 1);
  return TimeWindow(
    startUtc: _midnightUtc(startLocal, offsetResolver),
    endUtc: _midnightUtc(endLocal, offsetResolver),
  );
}

/// Convenience helper for aggregations.
TimeWindow periodUtcRange(
  DateTime now, {
  required Timeframe timeframe,
  TimeZoneOffsetResolver? offsetResolver,
}) {
  switch (timeframe) {
    case Timeframe.today:
      return todayUtcRange(now, offsetResolver: offsetResolver);
    case Timeframe.week:
      return weekUtcRange(now, offsetResolver: offsetResolver);
    case Timeframe.month:
      return monthUtcRange(now, offsetResolver: offsetResolver);
  }
}

enum Timeframe { today, week, month }
