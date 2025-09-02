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

  final double weight;
  final int reps;
  final int? rir;
  final String? note;
  final double? dropWeightKg;
  final int? dropReps;
  @JsonKey(fromJson: _setNumberFromJson)
  final int setNumber;

  WorkoutLogDto({
    required this.userId,
    required this.sessionId,
    this.exerciseId,
    required this.timestamp,
    required this.weight,
    required this.reps,
    this.rir,
    this.note,
    this.dropWeightKg,
    this.dropReps,
    required this.setNumber,
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
    rir: rir,
    note: note,
    dropWeightKg: dropWeightKg,
    dropReps: dropReps,
    setNumber: setNumber,
  );

  static DateTime _timestampToDate(Timestamp ts) => ts.toDate();
  static Timestamp _dateToTimestamp(DateTime date) => Timestamp.fromDate(date);
  static int _setNumberFromJson(dynamic v) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}
