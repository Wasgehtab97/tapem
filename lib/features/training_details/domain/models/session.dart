/// Enthält alle Sets einer einzelnen Session an einem Gerät.
class Session {
  final String sessionId;
  final String deviceId;
  final String deviceName;
  final String deviceDescription; // neu!
  final DateTime timestamp;
  final String note;
  final List<SessionSet> sets;

  Session({
    required this.sessionId,
    required this.deviceId,
    required this.deviceName,
    required this.deviceDescription, // neu!
    required this.timestamp,
    required this.note,
    required this.sets,
  });
}

class SessionSet {
  final double weight;
  final int reps;
  final List<DropSet> dropSets;

  SessionSet({
    required this.weight,
    required this.reps,
    this.dropSets = const [],
  });
}

class DropSet {
  final double weightKg;
  final int reps;

  DropSet({required this.weightKg, required this.reps});
}
