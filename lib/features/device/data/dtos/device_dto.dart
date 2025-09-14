// lib/features/device/data/dtos/device_dto.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tapem/features/device/domain/models/device.dart';

class DeviceDto {
  late final String uid;
  final int id;
  final String name;
  final List<String> muscleGroupIds;
  final String description;
  final String? nfcCode;
  final bool isMulti;
  final bool isCardio;
  final List<String> muscleGroups;
  final List<String> primaryMuscleGroups;
  final List<String> secondaryMuscleGroups;

  DeviceDto({
    required this.uid,
    required this.id,
    required this.name,
    List<String>? muscleGroupIds,
    required this.description,
    this.nfcCode,
    required this.isMulti,
    this.isCardio = false,
    List<String>? muscleGroups,
    List<String>? primaryMuscleGroups,
    List<String>? secondaryMuscleGroups,
  }) : muscleGroupIds = List.from(muscleGroupIds ?? []),
       muscleGroups = List.from(muscleGroups ?? []),
       primaryMuscleGroups = List.from(primaryMuscleGroups ?? []),
       secondaryMuscleGroups = List.from(secondaryMuscleGroups ?? []);

  factory DeviceDto.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return DeviceDto(
      uid: doc.id,
      id: (data['id'] as num?)?.toInt() ?? 0,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      nfcCode: data['nfcCode'] as String?,
      // if the field is missing or null, default to false
      isMulti: (data['isMulti'] as bool?) ?? false,
      isCardio: (data['isCardio'] as bool?) ?? false,
      muscleGroupIds:
          (data['muscleGroupIds'] as List<dynamic>? ?? [])
              .map((e) => e.toString())
              .toList(),
      muscleGroups:
          (data['muscleGroups'] as List<dynamic>? ?? [])
              .map((e) => e.toString())
              .toList(),
      primaryMuscleGroups:
          (data['primaryMuscleGroups'] as List<dynamic>? ?? [])
              .map((e) => e.toString())
              .toList(),
      secondaryMuscleGroups:
          (data['secondaryMuscleGroups'] as List<dynamic>? ?? [])
              .map((e) => e.toString())
              .toList(),
    );
  }

  /// Convert to your domain model
  Device toModel() => Device(
    uid: uid,
    id: id,
    name: name,
    muscleGroupIds: muscleGroupIds,
    muscleGroups: muscleGroups,
    primaryMuscleGroups: primaryMuscleGroups,
    secondaryMuscleGroups: secondaryMuscleGroups,
    description: description,
    nfcCode: nfcCode,
    isMulti: isMulti,
    isCardio: isCardio,
  );
}
