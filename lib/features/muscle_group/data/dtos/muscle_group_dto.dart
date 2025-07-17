import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/muscle_group.dart';

class MuscleGroupDto {
  late final String id;
  final String name;
  final MuscleRegion region;
  final List<String> deviceIds;
  final List<String> exerciseIds;

  MuscleGroupDto({
    required this.name,
    required this.region,
    List<String>? deviceIds,
    List<String>? exerciseIds,
  })  : deviceIds = List.from(deviceIds ?? []),
        exerciseIds = List.from(exerciseIds ?? []);

  factory MuscleGroupDto.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return MuscleGroupDto(
      name: data['name'] as String? ?? '',
      region: MuscleRegion.values.firstWhere(
        (r) => r.name == data['region'],
        orElse: () => MuscleRegion.core,
      ),
      deviceIds: (data['deviceIds'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      exerciseIds: (data['exerciseIds'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    )..id = doc.id;
  }

  MuscleGroup toModel() => MuscleGroup(
        id: id,
        name: name,
        region: region,
        deviceIds: deviceIds,
        exerciseIds: exerciseIds,
      );

  factory MuscleGroupDto.fromModel(MuscleGroup model) => MuscleGroupDto(
        name: model.name,
        region: model.region,
        deviceIds: model.deviceIds,
        exerciseIds: model.exerciseIds,
      )..id = model.id;

  Map<String, dynamic> toJson() => {
        'name': name,
        'region': region.name,
        'deviceIds': deviceIds,
        'exerciseIds': exerciseIds,
      };
}
