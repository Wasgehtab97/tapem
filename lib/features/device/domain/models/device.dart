// lib/features/device/domain/models/device.dart

class Device {
  final String uid;
  final int id;
  final String name;
  final String description;
  final String? nfcCode;
  final bool isMulti;

  Device({
    required this.uid,
    required this.id,
    required this.name,
    this.description = '',
    this.nfcCode,
    this.isMulti = false,
  });

  Device copyWith({
    String? uid,
    int? id,
    String? name,
    String? description,
    String? nfcCode,
    bool? isMulti,
  }) => Device(
    uid:         uid         ?? this.uid,
    id:          id          ?? this.id,
    name:        name        ?? this.name,
    description: description ?? this.description,
    nfcCode:     nfcCode     ?? this.nfcCode,
    isMulti:     isMulti     ?? this.isMulti,
  );

  factory Device.fromJson(Map<String, dynamic> json) => Device(
    uid:         json['uid']       as String,
    id:          json['id']        as int? ?? 0,
    name:        json['name']      as String,
    description: json['description'] as String? ?? '',
    nfcCode:     json['nfcCode']   as String?,
    isMulti:     json['isMulti']   as bool?   ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id':          id,
    'name':        name,
    'description': description,
    'nfcCode':     nfcCode,
    'isMulti':     isMulti,
  };
}
