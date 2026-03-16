import 'package:tapem/features/training_plan/application/training_plan_schedule_resolver.dart';
import 'package:tapem/features/training_plan/domain/models/training_plan.dart';

enum TrainingStartPlanResolutionReason {
  manualAssignment,
  scheduleSingleMatch,
  scheduleMultipleMatches,
  noResolvedPlan,
}

class TrainingStartPlanResolution {
  const TrainingStartPlanResolution({
    required this.reason,
    this.plannedPlan,
    this.candidatePlans = const <TrainingPlan>[],
  });

  final TrainingStartPlanResolutionReason reason;
  final TrainingPlan? plannedPlan;
  final List<TrainingPlan> candidatePlans;

  bool get hasMultipleCandidates => candidatePlans.length > 1;
}

class TrainingStartPlanResolutionResolver {
  const TrainingStartPlanResolutionResolver._();

  static TrainingStartPlanResolution resolve({
    required List<TrainingPlan> availablePlans,
    required DateTime date,
    String? assignmentPlanId,
  }) {
    if (assignmentPlanId != null && assignmentPlanId.isNotEmpty) {
      for (final plan in availablePlans) {
        if (plan.id == assignmentPlanId) {
          return TrainingStartPlanResolution(
            reason: TrainingStartPlanResolutionReason.manualAssignment,
            plannedPlan: plan,
          );
        }
      }
    }

    final matching = TrainingPlanScheduleResolver.matchingPlansForDate(
      plans: availablePlans,
      date: date,
    );
    if (matching.length == 1) {
      return TrainingStartPlanResolution(
        reason: TrainingStartPlanResolutionReason.scheduleSingleMatch,
        plannedPlan: matching.first,
      );
    }
    if (matching.length > 1) {
      return TrainingStartPlanResolution(
        reason: TrainingStartPlanResolutionReason.scheduleMultipleMatches,
        candidatePlans: matching,
      );
    }
    return const TrainingStartPlanResolution(
      reason: TrainingStartPlanResolutionReason.noResolvedPlan,
    );
  }
}
