// lib/features/device/domain/models/device.dart

class Device {
  final String uid;
  final int id;
  final String name;
  final List<String> muscleGroupIds;
  final String description;
  final String? nfcCode;
  final bool isMulti;
  final List<String> muscleGroups;

  Device({
    required this.uid,
    required this.id,
    required this.name,
    List<String>? muscleGroupIds,
    this.description = '',
    this.nfcCode,
    this.isMulti = false,
    List<String>? muscleGroups,
  })  : muscleGroupIds = List.unmodifiable(muscleGroupIds ?? []),
        muscleGroups   = List.unmodifiable(muscleGroups ?? []);

  Device copyWith({
    String? uid,
    int? id,
    String? name,
    String? description,
    String? nfcCode,
    bool? isMulti,
    List<String>? muscleGroupIds,
    List<String>? muscleGroups,
  }) => Device(
    uid:         uid         ?? this.uid,
    id:          id          ?? this.id,
    name:        name        ?? this.name,
    description: description ?? this.description,
    nfcCode:     nfcCode     ?? this.nfcCode,
    isMulti:     isMulti     ?? this.isMulti,
    muscleGroupIds: muscleGroupIds ?? this.muscleGroupIds,
    muscleGroups:   muscleGroups   ?? this.muscleGroups,
  );

  factory Device.fromJson(Map<String, dynamic> json) => Device(
    uid:         json['uid']       as String,
    id:          json['id']        as int? ?? 0,
    name:        json['name']      as String,
    description: json['description'] as String? ?? '',
    nfcCode:     json['nfcCode']   as String?,
    isMulti:     json['isMulti']   as bool?   ?? false,
    muscleGroupIds: (json['muscleGroupIds'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList(),
    muscleGroups: (json['muscleGroups'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'id':          id,
    'name':        name,
    'description': description,
    'nfcCode':     nfcCode,
    'isMulti':     isMulti,
    'muscleGroupIds': muscleGroupIds,
    'muscleGroups':   muscleGroups,
  };
}
