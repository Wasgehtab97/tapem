import 'package:cloud_firestore/cloud_firestore.dart';
import 'week_block.dart';

/// Domain model for a training plan consisting of multiple weeks.
class TrainingPlan {
  final String id;
  final String name;
  final DateTime createdAt;
  final String createdBy;
  final DateTime startDate;
  final List<WeekBlock> weeks;

  TrainingPlan({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.createdBy,
    required List<WeekBlock> weeks,
    required this.startDate,
  }) : weeks = List.from(weeks);

  TrainingPlan copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    String? createdBy,
    List<WeekBlock>? weeks,
    DateTime? startDate,
  }) {
    return TrainingPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      startDate: startDate ?? this.startDate,
      weeks: weeks ?? this.weeks,
    );
  }

  factory TrainingPlan.fromMap(String id, Map<String, dynamic> map) =>
      TrainingPlan(
        id: id,
        name: map['name'] as String? ?? '',
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        createdBy: map['createdBy'] as String? ?? '',
        startDate: (map['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        weeks:
            (map['weeks'] as List<dynamic>? ?? [])
                .map((e) => WeekBlock.fromMap(e as Map<String, dynamic>))
                .toList(),
      );

  Map<String, dynamic> toMap() => {
    'name': name,
    'createdAt': Timestamp.fromDate(createdAt),
    'createdBy': createdBy,
    'startDate': Timestamp.fromDate(startDate),
    'weeks': weeks.map((w) => w.toMap()).toList(),
  };
}
