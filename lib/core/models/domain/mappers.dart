// lib/core/models/domain/mappers.dart

import '../dto/gym_config_dto.dart';
import 'gym_config.dart';
// Neu hinzufügen:
import '../dto/device_dto.dart';
import 'device.dart';

// Schon vorhanden:
GymConfig toDomain(GymConfigDto dto) => GymConfig(
  id: dto.gymId,
  displayName: dto.name,
  primaryColorValue: int.parse('0xFF${dto.primaryColorHex}'),
);


Device toDomainDevice(DeviceDto dto) => Device(
  id: dto.deviceId,
  documentId: dto.documentId,
  name: dto.name,
  exerciseMode: dto.exerciseMode,
  secretCode: dto.secretCode,
);
