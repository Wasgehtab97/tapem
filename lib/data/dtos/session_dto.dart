// lib/data/dtos/session_dto.dart

import 'package:json_annotation/json_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tapem/core/models/timestamp_converter.dart';

part 'session_dto.g.dart';

/// Firestore-Session mit Datum und Liste von Sets.
@JsonSerializable(explicitToJson: true)
class SessionDto {
  final String id;

  @JsonKey(name: 'training_date')
  @TimestampConverter()
  final DateTime trainingDate;

  /// Jedes Set hat Nummer, Gewicht und Wiederholungen.
  final List<SetDto> data;

  SessionDto({
    required this.id,
    required this.trainingDate,
    required this.data,
  });

  factory SessionDto.fromJson(Map<String, dynamic> json) =>
      _$SessionDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SessionDtoToJson(this);
}

@JsonSerializable()
class SetDto {
  @JsonKey(name: 'set_number')
  final int setNumber;
  final String weight;
  final int reps;

  SetDto({
    required this.setNumber,
    required this.weight,
    required this.reps,
  });

  factory SetDto.fromJson(Map<String, dynamic> json) =>
      _$SetDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SetDtoToJson(this);
}
