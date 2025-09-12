abstract class WorkoutTimerTelemetry {
  void timerStart();
  void timerStopSave({required int durationMs, required String dayKey, required bool hasSets});
  void timerStopDiscard({required int durationMs, required String dayKey, required bool hasSets});
}
