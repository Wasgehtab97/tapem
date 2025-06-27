import 'exercise_entry.dart';

class DayEntry {
  final String day; // z.B. 'Mo', 'Do'
  final List<ExerciseEntry> exercises;

  DayEntry({required this.day, required List<ExerciseEntry> exercises})
      : exercises = List.from(exercises);

  factory DayEntry.fromMap(Map<String, dynamic> map) => DayEntry(
        day: map['day'] as String? ?? '',
        exercises: (map['exercises'] as List<dynamic>? ?? [])
            .map((e) => ExerciseEntry.fromMap(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toMap() => {
        'day': day,
        'exercises': exercises.map((e) => e.toMap()).toList(),
      };
}