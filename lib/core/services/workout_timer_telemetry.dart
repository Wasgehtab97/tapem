abstract class WorkoutTimerTelemetry {
  void timerStart();
  void timerStopSave({required int durationMs, required String dayKey, required bool hasSets});
  void timerStopDiscard({required int durationMs, required String dayKey, required bool hasSets});
  void sessionOpened({required String sessionId, required String gymId});
  void sessionActivityLogged({
    required String sessionId,
    required String gymId,
    required int setCount,
    required double durationMin,
  });
  void sessionClosedManual({
    required String sessionId,
    required String gymId,
    required int setCount,
    required double durationMin,
  });
  void sessionClosedIdle({
    required String sessionId,
    required String gymId,
    required int setCount,
    required double durationMin,
  });
}
