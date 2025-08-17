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
  final String? exerciseId;

  @JsonKey(fromJson: _timestampToDate, toJson: _dateToTimestamp)
  final DateTime timestamp;

  final double weight;
  final int reps;
  final int? rir;
  final String? note;
  final double? dropWeightKg;
  final int? dropReps;
  final List<DropSetDto>? dropSets;

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
    this.dropSets,
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
    exerciseId: exerciseId,
    timestamp: timestamp,
    weight: weight,
    reps: reps,
    rir: rir,
    note: note,
    dropSets: dropSets?.map((e) => DropSet(weightKg: e.weightKg, reps: e.reps)).toList() ??
        (dropWeightKg != null && dropReps != null
            ? [DropSet(weightKg: dropWeightKg!, reps: dropReps!)]
            : []),
  );

  static DateTime _timestampToDate(Timestamp ts) => ts.toDate();
  static Timestamp _dateToTimestamp(DateTime date) => Timestamp.fromDate(date);
}

class DropSetDto {
  final double weightKg;
  final int reps;

  DropSetDto({required this.weightKg, required this.reps});

  factory DropSetDto.fromJson(Map<String, dynamic> json) => DropSetDto(
        weightKg: (json['weightKg'] as num).toDouble(),
        reps: (json['reps'] as num).toInt(),
      );

  Map<String, dynamic> toJson() => {'weightKg': weightKg, 'reps': reps};
}
