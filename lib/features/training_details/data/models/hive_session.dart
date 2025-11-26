import 'package:hive/hive.dart';

part 'hive_session.g.dart';

/// Hive model for storing sessions locally
@HiveType(typeId: 0)
class HiveSession extends HiveObject {
  @HiveField(0)
  late String sessionId;

  @HiveField(1)
  late String gymId;

  @HiveField(2)
  late String userId;

  @HiveField(3)
  late String deviceId;

  @HiveField(4)
  late String deviceName;

  @HiveField(5)
  String? deviceDescription;

  @HiveField(6)
  late bool isMulti;

  @HiveField(7)
  String? exerciseId;

  @HiveField(8)
  String? exerciseName;

  @HiveField(9)
  late DateTime timestamp;

  @HiveField(10)
  String? note;

  @HiveField(11)
  late List<HiveSessionSet> sets;

  @HiveField(12)
  DateTime? startTime;

  @HiveField(13)
  DateTime? endTime;

  @HiveField(14)
  int? durationMs;

  @HiveField(15)
  late DateTime updatedAt;

  HiveSession();
}

/// Embedded Hive model for session sets
@HiveType(typeId: 1)
class HiveSessionSet {
  @HiveField(0)
  late double weight;

  @HiveField(1)
  late int reps;

  @HiveField(2)
  late int setNumber;

  @HiveField(3)
  late double dropWeightKg;

  @HiveField(4)
  late int dropReps;

  @HiveField(5)
  late bool isBodyweight;

  HiveSessionSet();
}
