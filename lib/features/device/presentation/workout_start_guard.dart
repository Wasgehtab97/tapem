import 'package:flutter/material.dart';
import 'package:tapem/core/services/workout_session_coordinator.dart';
import 'package:tapem/l10n/app_localizations.dart';

bool isWorkoutEditFlowActive(WorkoutSessionCoordinator coordinator) {
  return coordinator.isActiveWorkout;
}

void showWorkoutStartViaPlayRequiredSnackbar(BuildContext context) {
  final loc = AppLocalizations.of(context);
  final message =
      loc?.workoutStartViaPlayRequired ??
      'Bitte starte zuerst ein Training über den Play-Button.';
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
