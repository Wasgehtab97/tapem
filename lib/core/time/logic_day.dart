String logicDayKey(DateTime now, {String? tz}) {
  // For now, compute day key in UTC.
  return now.toUtc().toIso8601String().split('T').first;
}
