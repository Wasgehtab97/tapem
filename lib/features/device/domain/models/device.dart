// lib/features/device/domain/models/device.dart

class Device {
  final String  id;
  final String  name;
  final String  description;
  final String? nfcCode;

  Device({
    required this.id,
    required this.name,
    this.description = '',
    this.nfcCode,
  });

  Device copyWith({
    String? id,
    String? name,
    String? description,
    String? nfcCode,
  }) {
    return Device(
      id:          id          ?? this.id,
      name:        name        ?? this.name,
      description: description ?? this.description,
      nfcCode:     nfcCode     ?? this.nfcCode,
    );
  }

  factory Device.fromJson(Map<String, dynamic> json) => Device(
    id:          json['id']        as String,
    name:        json['name']      as String,
    description: json['description'] as String?    ?? '',
    nfcCode:     json['nfcCode']   as String?,
  );

  Map<String, dynamic> toJson() => {
    'name':        name,
    'description': description,
    'nfcCode':     nfcCode,
  };
}
