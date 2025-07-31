import 'package:cloud_firestore/cloud_firestore.dart';

import 'exercise_entry.dart';

class DayEntry {
  final DateTime date;
  final List<ExerciseEntry> exercises;

  DayEntry({required this.date, required List<ExerciseEntry> exercises})
    : exercises = List.from(exercises);

  factory DayEntry.fromMap(Map<String, dynamic> map) => DayEntry(
    date: (map['date'] as Timestamp).toDate(),
    exercises:
        (map['exercises'] as List<dynamic>? ?? [])
            .map((e) => ExerciseEntry.fromMap(e as Map<String, dynamic>))
            .toList(),
  );

  Map<String, dynamic> toMap() => {
    'date': Timestamp.fromDate(date),
    'exercises': exercises.map((e) => e.toMap()).toList(),
  };
}
