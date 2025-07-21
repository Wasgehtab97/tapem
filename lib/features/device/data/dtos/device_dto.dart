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
  final List<String> muscleGroups;

  DeviceDto({
    required this.uid,
    required this.id,
    required this.name,
    List<String>? muscleGroupIds,
    required this.description,
    this.nfcCode,
    required this.isMulti,
    List<String>? muscleGroups,
  })  : muscleGroupIds = List.from(muscleGroupIds ?? []),
        muscleGroups   = List.from(muscleGroups ?? []);

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
      muscleGroupIds: (data['muscleGroupIds'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      muscleGroups: (data['muscleGroups'] as List<dynamic>? ?? [])
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
    muscleGroups:   muscleGroups,
    description: description,
    nfcCode: nfcCode,
    isMulti: isMulti,
  );
}
