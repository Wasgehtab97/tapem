class DayInfo {
  DayInfo({required this.trained, required this.sessions});
  final bool trained;
  final int sessions;
}

class MonthCalendar {
  MonthCalendar({required this.yyyyMM, required this.days});
  final String yyyyMM;
  final Map<int, DayInfo> days;
}
