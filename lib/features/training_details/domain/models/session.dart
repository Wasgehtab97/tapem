/// Enthält alle Sets einer einzelnen Session an einem Gerät.
class Session {
  final String sessionId;
  final String deviceId;
  final String deviceName;
  final String deviceDescription;  // neu!
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
  SessionSet({ required this.weight, required this.reps });
}
