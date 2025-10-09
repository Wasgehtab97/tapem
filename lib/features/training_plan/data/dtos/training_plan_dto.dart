import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:tapem/features/training_plan/domain/models/training_plan.dart';
import 'package:tapem/features/training_plan/domain/models/split_day.dart';

class TrainingPlanDto {
  final String id;
  final String name;
  final DateTime createdAt;
  final String createdBy;
  final List<SplitDay> days;

  TrainingPlanDto({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.createdBy,
    required this.days,
  });

  factory TrainingPlanDto.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return TrainingPlanDto(
      id: doc.id,
      name: data['name'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] as String? ?? '',
      days: (data['days'] as List<dynamic>? ?? [])
          .map((w) => SplitDay.fromMap(w as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'createdAt': Timestamp.fromDate(createdAt),
        'createdBy': createdBy,
        'days': days.map((w) => w.toMap()).toList(),
      };

  TrainingPlan toModel() => TrainingPlan(
        id: id,
        name: name,
        createdAt: createdAt,
        createdBy: createdBy,
        days: days,
      );

  factory TrainingPlanDto.fromModel(TrainingPlan plan) => TrainingPlanDto(
        id: plan.id,
        name: plan.name,
        createdAt: plan.createdAt,
        createdBy: plan.createdBy,
        days: plan.days,
      );
}
