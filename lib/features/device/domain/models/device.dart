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
  final List<String> primaryMuscleGroups;
  final List<String> secondaryMuscleGroups;

  final String? manufacturerId; // NEW
  final String? manufacturerName; // NEW: Denormalized for easy display

  Device({
    required this.uid,
    required this.id,
    required this.name,
    List<String>? muscleGroupIds,
    this.description = '',
    this.nfcCode,
    this.isMulti = false,
    List<String>? muscleGroups,
    List<String>? primaryMuscleGroups,
    List<String>? secondaryMuscleGroups,
    this.manufacturerId,
    this.manufacturerName,
  }) : muscleGroupIds = List.unmodifiable(muscleGroupIds ?? []),
       primaryMuscleGroups = List.unmodifiable(primaryMuscleGroups ?? []),
       secondaryMuscleGroups = List.unmodifiable(secondaryMuscleGroups ?? []),
       muscleGroups = List.unmodifiable(
         muscleGroups ??
             [...(primaryMuscleGroups ?? []), ...(secondaryMuscleGroups ?? [])],
       );

  Device copyWith({
    String? uid,
    int? id,
    String? name,
    String? description,
    String? nfcCode,
    bool? isMulti,
    List<String>? muscleGroupIds,
    List<String>? muscleGroups,
    List<String>? primaryMuscleGroups,
    List<String>? secondaryMuscleGroups,
    String? manufacturerId,
    String? manufacturerName,
  }) => Device(
    uid: uid ?? this.uid,
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    nfcCode: nfcCode ?? this.nfcCode,
    isMulti: isMulti ?? this.isMulti,
    muscleGroupIds: muscleGroupIds ?? this.muscleGroupIds,
    muscleGroups:
        muscleGroups ??
        [
          ...(primaryMuscleGroups ?? this.primaryMuscleGroups),
          ...(secondaryMuscleGroups ?? this.secondaryMuscleGroups),
        ],
    primaryMuscleGroups: primaryMuscleGroups ?? this.primaryMuscleGroups,
    secondaryMuscleGroups: secondaryMuscleGroups ?? this.secondaryMuscleGroups,
    manufacturerId: manufacturerId ?? this.manufacturerId,
    manufacturerName: manufacturerName ?? this.manufacturerName,
  );

  factory Device.fromJson(Map<String, dynamic> json) {
    final primary = (json['primaryMuscleGroups'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    final secondary = (json['secondaryMuscleGroups'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();

    List<String>? muscleGroups;
    if (json.containsKey('muscleGroups')) {
      final rawMuscleGroups = json['muscleGroups'];
      if (rawMuscleGroups is List) {
        muscleGroups = rawMuscleGroups.map((e) => e.toString()).toList();
      } else if (rawMuscleGroups != null) {
        muscleGroups = [rawMuscleGroups.toString()];
      } else {
        muscleGroups = null;
      }
    }

    return Device(
      uid: json['uid'] as String,
      id: json['id'] as int? ?? 0,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      nfcCode: json['nfcCode'] as String?,
      isMulti: json['isMulti'] as bool? ?? false,
      muscleGroupIds: (json['muscleGroupIds'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      primaryMuscleGroups: primary,
      secondaryMuscleGroups: secondary,
      muscleGroups: muscleGroups ?? [...primary, ...secondary],
      manufacturerId: json['manufacturerId'] as String?,
      manufacturerName: json['manufacturerName'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'nfcCode': nfcCode,
    'isMulti': isMulti,
    'muscleGroupIds': muscleGroupIds,
    'muscleGroups': muscleGroups,
    'primaryMuscleGroups': primaryMuscleGroups,
    'secondaryMuscleGroups': secondaryMuscleGroups,
    'manufacturerId': manufacturerId,
    'manufacturerName': manufacturerName,
  };

  /// Returns the manufacturer name if available, otherwise falls back to the description.
  String get displaySubtitle =>
      (manufacturerName?.isNotEmpty ?? false) ? manufacturerName! : description;
}
