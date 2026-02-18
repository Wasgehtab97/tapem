const int kWorkoutInactivityMinutes = int.fromEnvironment(
  'WORKOUT_INACTIVITY_MINUTES',
  defaultValue: 60,
);

const int kWorkoutInactivityMs = kWorkoutInactivityMinutes * 60 * 1000;

const Duration kWorkoutInactivityDuration = Duration(
  milliseconds: kWorkoutInactivityMs,
);
