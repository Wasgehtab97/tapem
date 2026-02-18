import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/features/device/presentation/services/workout_entry_orchestrator.dart';

final workoutEntryOrchestratorProvider = Provider<WorkoutEntryOrchestrator>((
  ref,
) {
  return WorkoutEntryOrchestrator();
});
