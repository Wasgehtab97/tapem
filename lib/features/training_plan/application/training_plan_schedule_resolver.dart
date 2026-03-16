import 'package:tapem/features/training_plan/domain/models/training_plan.dart';

class TrainingPlanScheduleResolver {
  const TrainingPlanScheduleResolver._();

  static List<TrainingPlan> matchingPlansForDate({
    required List<TrainingPlan> plans,
    required DateTime date,
  }) {
    final matching = <TrainingPlan>[
      for (final plan in plans)
        if (plan.schedule?.matchesDate(date) == true) plan,
    ];
    matching.sort(_sortByRecencyDesc);
    return matching;
  }

  static TrainingPlan? resolvePreferredPlanForDate({
    required List<TrainingPlan> plans,
    required DateTime date,
  }) {
    final matching = matchingPlansForDate(plans: plans, date: date);
    if (matching.isEmpty) return null;
    return matching.first;
  }

  static int _sortByRecencyDesc(TrainingPlan a, TrainingPlan b) {
    final byUpdated = b.updatedAt.compareTo(a.updatedAt);
    if (byUpdated != 0) return byUpdated;
    final byCreated = b.createdAt.compareTo(a.createdAt);
    if (byCreated != 0) return byCreated;
    return a.id.compareTo(b.id);
  }
}
