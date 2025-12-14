/// Enthält alle Sets einer einzelnen Session an einem Gerät.
class Session {
  final String sessionId;
  final String gymId;
  final String userId;
  final String deviceId;
  final String deviceName;
  final String? deviceDescription; // nullable
  final String? exerciseId;
  final String? exerciseName;
  final bool isMulti;
  final DateTime timestamp;
  final String note;
  final List<SessionSet> sets;

  /// Timestamp of when the session started, if known.
  final DateTime? startTime;

  /// Timestamp of when the session ended, if known.
  final DateTime? endTime;

  /// Total duration of the session in milliseconds.
  final int? durationMs;

  Session({
    required this.sessionId,
    required this.gymId,
    required this.userId,
    required this.deviceId,
    required this.deviceName,
    this.deviceDescription, // nullable, not required
    this.exerciseId,
    this.exerciseName,
    this.isMulti = false,
    required this.timestamp,
    required this.note,
    required this.sets,
    this.startTime,
    this.endTime,
    this.durationMs,
  });

  Session copyWith({
    String? sessionId,
    String? gymId,
    String? userId,
    String? deviceId,
    String? deviceName,
    String? deviceDescription,
    String? exerciseId,
    String? exerciseName,
    bool? isMulti,
    DateTime? timestamp,
    String? note,
    List<SessionSet>? sets,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMs,
  }) {
    return Session(
      sessionId: sessionId ?? this.sessionId,
      gymId: gymId ?? this.gymId,
      userId: userId ?? this.userId,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      deviceDescription: deviceDescription ?? this.deviceDescription,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      isMulti: isMulti ?? this.isMulti,
      timestamp: timestamp ?? this.timestamp,
      note: note ?? this.note,
      sets: sets ?? List<SessionSet>.from(this.sets),
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMs: durationMs ?? this.durationMs,
    );
  }
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
