import 'package:cloud_firestore/cloud_firestore.dart';

import 'split_day.dart';

/// Domain model for a training plan consisting of multiple split days.
class TrainingPlan {
  final String id;
  final String name;
  final DateTime createdAt;
  final String createdBy;
  final List<SplitDay> days;

  TrainingPlan({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.createdBy,
    required List<SplitDay> days,
  }) : days = List<SplitDay>.from(days);

  int get splitDayCount => days.length;

  TrainingPlan copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    String? createdBy,
    List<SplitDay>? days,
  }) {
    return TrainingPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      days: days ?? this.days,
    );
  }

  factory TrainingPlan.fromMap(String id, Map<String, dynamic> map) =>
      TrainingPlan(
        id: id,
        name: map['name'] as String? ?? '',
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        createdBy: map['createdBy'] as String? ?? '',
        days: (map['days'] as List<dynamic>? ?? [])
            .map((e) => SplitDay.fromMap(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'createdAt': Timestamp.fromDate(createdAt),
        'createdBy': createdBy,
        'days': days.map((w) => w.toMap()).toList(),
      };
}
