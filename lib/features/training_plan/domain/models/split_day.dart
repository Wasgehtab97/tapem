import 'exercise_entry.dart';

class SplitDay {
  final int index;
  final String? name;
  final List<ExerciseEntry> exercises;

  SplitDay({
    required this.index,
    List<ExerciseEntry>? exercises,
    this.name,
  }) : exercises = List<ExerciseEntry>.from(exercises ?? []);

  SplitDay copyWith({
    int? index,
    String? name,
    List<ExerciseEntry>? exercises,
  }) {
    return SplitDay(
      index: index ?? this.index,
      name: name ?? this.name,
      exercises: exercises ?? this.exercises,
    );
  }

  factory SplitDay.fromMap(Map<String, dynamic> map) => SplitDay(
        index: (map['index'] as num?)?.toInt() ?? 0,
        name: map['name'] as String?,
        exercises: (map['exercises'] as List<dynamic>? ?? [])
            .map((e) => ExerciseEntry.fromMap(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toMap() => {
        'index': index,
        if (name != null) 'name': name,
        'exercises': exercises.map((e) => e.toMap()).toList(),
      };
}
