import 'dart:ui';

import '../dto/gym_config_dto.dart';
import 'gym_config.dart';
import '../dto/device_dto.dart';
import 'device.dart';

/// Hilfsfunktion: Parst einen Hex-String (mit/ohne "#") in eine [Color].
Color _hexToColor(String hex) {
  final cleaned = hex.replaceAll('#', '');
  final full = (cleaned.length == 6) ? 'FF$cleaned' : cleaned;
  return Color(int.parse(full, radix: 16));
}

/// Konvertiert [GymConfigDto] zu [GymConfig].
GymConfig toDomain(GymConfigDto dto) {
  return GymConfig(
    id: dto.gymId,
    displayName: dto.name,
    primaryColor: _hexToColor(dto.primaryColorHex),
    accentColor: _hexToColor(dto.accentColorHex),
    logoUrl: dto.logoUrl,
  );
}

/// Konvertiert [DeviceDto] zu [Device].
Device toDomainDevice(DeviceDto dto) => Device(
      id: dto.deviceId,
      documentId: dto.documentId,
      name: dto.name,
      exerciseMode: dto.exerciseMode,
      secretCode: dto.secretCode,
    );
