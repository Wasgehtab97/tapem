// lib/features/device/domain/models/device.dart
class Device {
  final String id;
  final String name;
  final String description;

  Device({
    required this.id,
    required this.name,
    this.description = '',
  });
}
