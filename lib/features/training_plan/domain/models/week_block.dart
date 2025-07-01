import 'day_entry.dart';

class WeekBlock {
  final int weekNumber;
  final List<DayEntry> days;

  WeekBlock({required this.weekNumber, required List<DayEntry> days})
    : days = List.from(days);

  factory WeekBlock.fromMap(Map<String, dynamic> map) => WeekBlock(
    weekNumber: (map['weekNumber'] as num?)?.toInt() ?? 0,
    days:
        (map['days'] as List<dynamic>? ?? [])
            .map((e) => DayEntry.fromMap(e as Map<String, dynamic>))
            .toList(),
  );

  Map<String, dynamic> toMap() => {
    'weekNumber': weekNumber,
    'days': days.map((d) => d.toMap()).toList(),
  };
}
