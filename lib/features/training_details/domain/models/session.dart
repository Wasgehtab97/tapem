/// Enthält alle Sets einer einzelnen Session an einem Gerät.
class Session {
  final String sessionId;
  final String deviceId;
  final String deviceName;
  final String deviceDescription; // neu!
  final DateTime timestamp;
  final String note;
  final List<SessionSet> sets;

  /// True if this session represents a cardio workout.
  final bool isCardio;

  /// Cardio mode: "timed", "steady", or "intervals".
  final String? mode;

  /// Total duration in seconds for cardio sessions.
  final int? durationSec;

  /// Steady speed in km/h for steady cardio sessions.
  final double? speedKmH;

  /// Interval details for interval cardio sessions.
  final List<CardioInterval>? intervals;

  /// Timestamp of when the session started, if known.
  final DateTime? startTime;

  /// Timestamp of when the session ended, if known.
  final DateTime? endTime;

  /// Total duration of the session in milliseconds.
  final int? durationMs;

  Session({
    required this.sessionId,
    required this.deviceId,
    required this.deviceName,
    required this.deviceDescription, // neu!
    required this.timestamp,
    required this.note,
    required this.sets,
    this.startTime,
    this.endTime,
    this.durationMs,
    this.isCardio = false,
    this.mode,
    this.durationSec,
    this.speedKmH,
    this.intervals,
  });
}

class SessionSet {
  final double weight;
  final int reps;
  final int setNumber;
  final double? dropWeightKg;
  final int? dropReps;
  final bool isBodyweight;
  SessionSet({
    required this.weight,
    required this.reps,
    required this.setNumber,
    this.dropWeightKg,
    this.dropReps,
    this.isBodyweight = false,
  });
}

class CardioInterval {
  final int? durationSec;
  final double? speedKmH;
  CardioInterval({this.durationSec, this.speedKmH});
}
