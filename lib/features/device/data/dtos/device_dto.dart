// lib/features/device/data/dtos/device_dto.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tapem/features/device/domain/models/device.dart';

class DeviceDto {
  late final String uid;
  final int id;
  final String name;
  final String description;
  final String? nfcCode;
  final bool isMulti;

  DeviceDto({
    required this.uid,
    required this.id,
    required this.name,
    required this.description,
    this.nfcCode,
    required this.isMulti,
  });

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
    );
  }

  /// Convert to your domain model
  Device toModel() => Device(
    uid: uid,
    id: id,
    name: name,
    description: description,
    nfcCode: nfcCode,
    isMulti: isMulti,
  );
}
