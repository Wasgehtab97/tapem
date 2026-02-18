class ReportDailyAggregate {
  const ReportDailyAggregate({
    required this.dayUtc,
    required this.totalLogs,
    required this.totalSessions,
    required this.deviceSessionCounts,
    required this.hourBuckets,
  });

  final DateTime dayUtc;
  final int totalLogs;
  final int totalSessions;
  final Map<String, int> deviceSessionCounts;
  final Map<int, int> hourBuckets;

  factory ReportDailyAggregate.fromMap(
    String dayKey,
    Map<String, dynamic> data,
  ) {
    final parsedDay = _parseDayKey(dayKey) ?? DateTime.now().toUtc();
    final rawDeviceSessions = data['deviceSessionCounts'];
    final rawHourBuckets = data['hourBuckets'];
    return ReportDailyAggregate(
      dayUtc: parsedDay,
      totalLogs: _asInt(data['totalLogs']),
      totalSessions: _asInt(data['totalSessions']),
      deviceSessionCounts: _toStringIntMap(rawDeviceSessions),
      hourBuckets: _toHourBucketMap(rawHourBuckets),
    );
  }

  static DateTime? _parseDayKey(String dayKey) {
    if (dayKey.length != 8) {
      return null;
    }
    final year = int.tryParse(dayKey.substring(0, 4));
    final month = int.tryParse(dayKey.substring(4, 6));
    final day = int.tryParse(dayKey.substring(6, 8));
    if (year == null || month == null || day == null) {
      return null;
    }
    return DateTime.utc(year, month, day);
  }

  static int _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return 0;
  }

  static Map<String, int> _toStringIntMap(Object? raw) {
    if (raw is! Map) {
      return const <String, int>{};
    }
    final result = <String, int>{};
    raw.forEach((key, value) {
      if (key is String) {
        result[key] = _asInt(value);
      }
    });
    return result;
  }

  static Map<int, int> _toHourBucketMap(Object? raw) {
    if (raw is! Map) {
      return const <int, int>{};
    }
    final result = <int, int>{};
    raw.forEach((key, value) {
      final hour = int.tryParse(key.toString());
      if (hour != null && hour >= 0 && hour <= 23) {
        result[hour] = _asInt(value);
      }
    });
    return result;
  }
}
