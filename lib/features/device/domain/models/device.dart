// lib/features/device/domain/models/device.dart

class Device {
  final String id;
  final String name;
  final String description;
  final String? nfcCode;
  final bool isMulti;

  Device({
    required this.id,
    required this.name,
    this.description = '',
    this.nfcCode,
    this.isMulti = false,
  });

  Device copyWith({
    String? id,
    String? name,
    String? description,
    String? nfcCode,
    bool? isMulti,
  }) => Device(
    id:          id          ?? this.id,
    name:        name        ?? this.name,
    description: description ?? this.description,
    nfcCode:     nfcCode     ?? this.nfcCode,
    isMulti:     isMulti     ?? this.isMulti,
  );

  factory Device.fromJson(Map<String, dynamic> json) => Device(
    id:          json['id']        as String,
    name:        json['name']      as String,
    description: json['description'] as String? ?? '',
    nfcCode:     json['nfcCode']   as String?,
    isMulti:     json['isMulti']   as bool?   ?? false,
  );

  Map<String, dynamic> toJson() => {
    'name':        name,
    'description': description,
    'nfcCode':     nfcCode,
    'isMulti':     isMulti,
  };
}
