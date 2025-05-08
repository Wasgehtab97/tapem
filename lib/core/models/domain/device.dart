// lib/core/models/domain/device.dart

/// Domain‐Klasse für ein Fitnessstudio‐Gerät
class Device {
  final int id;
  final String documentId;
  final String name;
  final String exerciseMode;
  final String secretCode;

  Device({
    required this.id,
    required this.documentId,
    required this.name,
    required this.exerciseMode,
    required this.secretCode,
  });
}
