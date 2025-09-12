/// Returns a `YYYY-MM-DD` key for the given local [date].
///
/// The [date] is treated as already being in the desired locale/timezone and
/// no conversion is performed. This ensures that sessions crossing midnight are
/// still attributed to the day of their *start* in the user's local timezone.
String logicDayKey(DateTime date) {
  return date.toIso8601String().split('T').first;
}
