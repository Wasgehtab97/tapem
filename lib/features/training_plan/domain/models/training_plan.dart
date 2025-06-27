import 'week_block.dart';

/// Domain model for a training plan consisting of multiple weeks.
class TrainingPlan {
  final String id;
  final String name;
  final List<WeekBlock> weeks;

  TrainingPlan({
    required this.id,
    required this.name,
    required List<WeekBlock> weeks,
  }) : weeks = List.from(weeks);

  TrainingPlan copyWith({String? id, String? name, List<WeekBlock>? weeks}) {
    return TrainingPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      weeks: weeks ?? this.weeks,
    );
  }

  factory TrainingPlan.fromMap(String id, Map<String, dynamic> map) =>
      TrainingPlan(
        id: id,
        name: map['name'] as String? ?? '',
        weeks:
            (map['weeks'] as List<dynamic>? ?? [])
                .map((e) => WeekBlock.fromMap(e as Map<String, dynamic>))
                .toList(),
      );

  Map<String, dynamic> toMap() => {
    'name': name,
    'weeks': weeks.map((w) => w.toMap()).toList(),
  };
}
