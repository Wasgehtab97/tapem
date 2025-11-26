import 'package:isar/isar.dart';

part 'local_session.g.dart';

@collection
class LocalSession {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String sessionId;

  @Index()
  late String gymId;

  @Index()
  late String userId;

  @Index()
  late String deviceId;

  late String deviceName;
  late String deviceDescription;
  late bool isMulti;

  String? exerciseId;
  String? exerciseName;

  @Index()
  late DateTime timestamp;

  String? note;

  late List<LocalSessionSet> sets;

  DateTime? startTime;
  DateTime? endTime;
  int? durationMs;

  @Index()
  late DateTime updatedAt; // For sync conflict resolution
}

@embedded
class LocalSessionSet {
  late double weight;
  late int reps;
  late int setNumber;
  late double dropWeightKg;
  late int dropReps;
  late bool isBodyweight;
}
