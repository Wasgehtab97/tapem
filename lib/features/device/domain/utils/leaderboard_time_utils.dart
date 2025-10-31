class LeaderboardTimeRange {
  final DateTime startUtc;
  final DateTime endUtc;

  const LeaderboardTimeRange({
    required this.startUtc,
    required this.endUtc,
  });
}

enum LeaderboardPeriod { today, week, month }

LeaderboardTimeRange resolveTimeRangeUtc(
  LeaderboardPeriod period, {
  DateTime? reference,
}) {
  final now = reference ?? DateTime.now();
  final localNow = now.isUtc ? now.toLocal() : now;
  final startLocal = switch (period) {
    LeaderboardPeriod.today => DateTime(localNow.year, localNow.month, localNow.day),
    LeaderboardPeriod.week => _startOfWeek(localNow),
    LeaderboardPeriod.month => DateTime(localNow.year, localNow.month),
  };
  final endLocal = switch (period) {
    LeaderboardPeriod.today => startLocal.add(const Duration(days: 1)),
    LeaderboardPeriod.week => startLocal.add(const Duration(days: 7)),
    LeaderboardPeriod.month => DateTime(localNow.year, localNow.month + 1),
  };
  return LeaderboardTimeRange(
    startUtc: startLocal.toUtc(),
    endUtc: endLocal.toUtc(),
  );
}

DateTime _startOfWeek(DateTime date) {
  final weekday = date.weekday; // Monday == 1
  final difference = weekday - DateTime.monday;
  return DateTime(date.year, date.month, date.day).subtract(Duration(days: difference));
}
