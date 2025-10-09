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
  final int splitDays;

  TrainingPlan({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.createdBy,
    required List<WeekBlock> weeks,
    required this.startDate,
    this.splitDays = 1,
  })  : weeks = List.from(weeks),
        assert(splitDays >= 1, 'splitDays must be at least 1');

  TrainingPlan copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    String? createdBy,
    List<WeekBlock>? weeks,
    DateTime? startDate,
    int? splitDays,
  }) {
    return TrainingPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      startDate: startDate ?? this.startDate,
      weeks: weeks ?? this.weeks,
      splitDays: splitDays ?? this.splitDays,
    );
  }

  factory TrainingPlan.fromMap(String id, Map<String, dynamic> map) =>
      TrainingPlan(
        id: id,
        name: map['name'] as String? ?? '',
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        createdBy: map['createdBy'] as String? ?? '',
        startDate: (map['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        splitDays: (map['splitDays'] as num?)?.toInt() ?? 1,
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
    'splitDays': splitDays,
    'weeks': weeks.map((w) => w.toMap()).toList(),
  };
}
