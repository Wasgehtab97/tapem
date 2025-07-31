// lib/features/history/data/dtos/workout_log_dto.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:tapem/features/history/domain/models/workout_log.dart';

part 'workout_log_dto.g.dart';

@JsonSerializable()
class WorkoutLogDto {
  @JsonKey(ignore: true)
  late String id;

  final String userId;
  final String sessionId;

  @JsonKey(fromJson: _timestampToDate, toJson: _dateToTimestamp)
  final DateTime timestamp;

  final double weight;
  final int reps;
  final int? rir;
  final String? note;

  WorkoutLogDto({
    required this.userId,
    required this.sessionId,
    required this.timestamp,
    required this.weight,
    required this.reps,
    this.rir,
    this.note,
  });

  factory WorkoutLogDto.fromJson(Map<String, dynamic> json) =>
      _$WorkoutLogDtoFromJson(json);

  Map<String, dynamic> toJson() => _$WorkoutLogDtoToJson(this);

  /// Dokument → DTO
  factory WorkoutLogDto.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    final dto = WorkoutLogDto.fromJson(data);
    dto.id = doc.id;
    return dto;
  }

  /// DTO → Domain-Modell
  WorkoutLog toModel() => WorkoutLog(
    id: id,
    userId: userId,
    sessionId: sessionId,
    timestamp: timestamp,
    weight: weight,
    reps: reps,
    rir: rir,
    note: note,
  );

  static DateTime _timestampToDate(Timestamp ts) => ts.toDate();
  static Timestamp _dateToTimestamp(DateTime date) => Timestamp.fromDate(date);
}
