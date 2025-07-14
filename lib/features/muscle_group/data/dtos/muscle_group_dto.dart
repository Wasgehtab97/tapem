import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/muscle_group.dart';

class MuscleGroupDto {
  late final String id;
  final String name;
  final List<String> deviceIds;

  MuscleGroupDto({
    required this.name,
    List<String>? deviceIds,
  }) : deviceIds = List.from(deviceIds ?? []);

  factory MuscleGroupDto.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return MuscleGroupDto(
      name: data['name'] as String? ?? '',
      deviceIds: (data['deviceIds'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    )..id = doc.id;
  }

  MuscleGroup toModel() => MuscleGroup(
        id: id,
        name: name,
        deviceIds: deviceIds,
      );

  factory MuscleGroupDto.fromModel(MuscleGroup model) => MuscleGroupDto(
        name: model.name,
        deviceIds: model.deviceIds,
      )..id = model.id;

  Map<String, dynamic> toJson() => {
        'name': name,
        'deviceIds': deviceIds,
      };
}
