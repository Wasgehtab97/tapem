// lib/features/history/data/dtos/workout_log_dto.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:tapem/features/history/domain/models/workout_log.dart';

part 'workout_log_dto.g.dart';

@JsonSerializable()
class WorkoutLogDto {
  @JsonKey(ignore: true)
  late String id;
  @JsonKey(ignore: true)
  late DocumentReference<Map<String, dynamic>> reference;

  final String userId;
  final String sessionId;
  final String? exerciseId;

  @JsonKey(fromJson: _timestampToDate, toJson: _dateToTimestamp)
  final DateTime timestamp;

  final double? weight;
  final int? reps;
  final double? dropWeightKg;
  final int? dropReps;
  @JsonKey(fromJson: _setNumberFromJson)
  final int setNumber;
  final bool isBodyweight;

  // Cardio fields
  final bool isCardio;
  final String? mode;
  final int? durationSec;
  final double? speedKmH;
  @JsonKey(fromJson: _intervalsFromJson, toJson: _intervalsToJson)
  final List<Map<String, dynamic>>? intervals;

  WorkoutLogDto({
    required this.userId,
    required this.sessionId,
    this.exerciseId,
    required this.timestamp,
    this.weight,
    this.reps,
    this.dropWeightKg,
    this.dropReps,
    required this.setNumber,
    this.isBodyweight = false,
    this.isCardio = false,
    this.mode,
    this.durationSec,
    this.speedKmH,
    this.intervals,
  });

  factory WorkoutLogDto.fromJson(Map<String, dynamic> json) =>
      _$WorkoutLogDtoFromJson(json);

  Map<String, dynamic> toJson() => _$WorkoutLogDtoToJson(this);

  /// Dokument → DTO
  factory WorkoutLogDto.fromDocument(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    data['setNumber'] = data['setNumber'] ?? data['number'];
    final dto = WorkoutLogDto.fromJson(data);
    dto.id = doc.id;
    dto.reference = doc.reference;
    return dto;
  }

  /// DTO → Domain-Modell
  WorkoutLog toModel() => WorkoutLog(
    id: id,
    userId: userId,
    sessionId: sessionId,
    exerciseId: exerciseId,
    timestamp: timestamp,
    weight: weight,
    reps: reps,
    dropWeightKg: dropWeightKg,
    dropReps: dropReps,
    setNumber: setNumber,
    isBodyweight: isBodyweight,
    isCardio: isCardio,
    mode: mode,
    durationSec: durationSec,
    speedKmH: speedKmH,
    intervals: intervals,
  );

  static DateTime _timestampToDate(Timestamp ts) => ts.toDate();
  static Timestamp _dateToTimestamp(DateTime date) => Timestamp.fromDate(date);
  static int _setNumberFromJson(dynamic v) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static List<Map<String, dynamic>>? _intervalsFromJson(List<dynamic>? list) =>
      list?.map((e) => Map<String, dynamic>.from(e as Map)).toList();

  static List<Map<String, dynamic>>? _intervalsToJson(
          List<Map<String, dynamic>>? list) =>
      list;
}
