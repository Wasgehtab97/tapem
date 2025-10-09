import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:tapem/features/training_plan/domain/models/training_plan.dart';
import 'package:tapem/features/training_plan/domain/models/week_block.dart';
import 'package:tapem/features/training_plan/domain/models/day_entry.dart';
import 'package:tapem/features/training_plan/domain/models/exercise_entry.dart';

class TrainingPlanDto {
  final String id;
  final String name;
  final DateTime createdAt;
  final String createdBy;
  final DateTime startDate;
  final List<WeekBlock> weeks;
  final int splitDays;

  TrainingPlanDto({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.createdBy,
    required this.weeks,
    required this.startDate,
    this.splitDays = 1,
  });

  factory TrainingPlanDto.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    List<WeekBlock>? weeks,
  }) {
    final data = doc.data()!;
    return TrainingPlanDto(
      id: doc.id,
      name: data['name'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] as String? ?? '',
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      splitDays: (data['splitDays'] as num?)?.toInt() ?? 1,
      weeks:
          weeks ??
          (data['weeks'] as List<dynamic>? ?? [])
              .map((w) => WeekBlock.fromMap(w as Map<String, dynamic>))
              .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'createdAt': Timestamp.fromDate(createdAt),
    'createdBy': createdBy,
    'startDate': Timestamp.fromDate(startDate),
    'splitDays': splitDays,
  };

  TrainingPlan toModel() => TrainingPlan(
    id: id,
    name: name,
    createdAt: createdAt,
    createdBy: createdBy,
    startDate: startDate,
    weeks: weeks,
    splitDays: splitDays,
  );

  factory TrainingPlanDto.fromModel(TrainingPlan plan) => TrainingPlanDto(
    id: plan.id,
    name: plan.name,
    createdAt: plan.createdAt,
    createdBy: plan.createdBy,
    startDate: plan.startDate,
    weeks: plan.weeks,
    splitDays: plan.splitDays,
  );
}
