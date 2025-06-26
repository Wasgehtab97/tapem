import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/training_plan.dart';
import '../../domain/models/week_block.dart';
import '../../domain/models/day_entry.dart';
import '../../domain/models/exercise_entry.dart';

class TrainingPlanDto {
  final String id;
  final String name;
  final List<WeekBlock> weeks;

  TrainingPlanDto({required this.id, required this.name, required this.weeks});

  factory TrainingPlanDto.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return TrainingPlanDto(
      id: doc.id,
      name: data['name'] as String? ?? '',
      weeks:
          (data['weeks'] as List<dynamic>? ?? [])
              .map((w) => WeekBlock.fromMap(w as Map<String, dynamic>))
              .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'weeks': weeks.map((w) => w.toMap()).toList(),
  };

  TrainingPlan toModel() => TrainingPlan(id: id, name: name, weeks: weeks);

  factory TrainingPlanDto.fromModel(TrainingPlan plan) =>
      TrainingPlanDto(id: plan.id, name: plan.name, weeks: plan.weeks);
}
