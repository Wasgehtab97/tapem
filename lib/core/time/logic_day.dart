String logicDayKey(DateTime nowUtc) {
  final utc = nowUtc.toUtc();
  return utc.toIso8601String().split('T').first;
}
