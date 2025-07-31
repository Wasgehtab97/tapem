enum MuscleRegion { chest, back, shoulders, arms, core, legs }

class MuscleGroup {
  final String id;
  final String name;
  final MuscleRegion region;
  final List<String> primaryDeviceIds;
  final List<String> secondaryDeviceIds;
  final List<String> exerciseIds;

  MuscleGroup({
    required this.id,
    required this.name,
    this.region = MuscleRegion.core,
    List<String>? primaryDeviceIds,
    List<String>? secondaryDeviceIds,
    List<String>? exerciseIds,
  }) : primaryDeviceIds = List.unmodifiable(primaryDeviceIds ?? []),
       secondaryDeviceIds = List.unmodifiable(secondaryDeviceIds ?? []),
       exerciseIds = List.unmodifiable(exerciseIds ?? []);

  /// Convenience getter combining both device lists
  List<String> get deviceIds =>
      List.unmodifiable([...primaryDeviceIds, ...secondaryDeviceIds]);

  MuscleGroup copyWith({
    String? id,
    String? name,
    MuscleRegion? region,
    List<String>? primaryDeviceIds,
    List<String>? secondaryDeviceIds,
    List<String>? exerciseIds,
  }) => MuscleGroup(
    id: id ?? this.id,
    name: name ?? this.name,
    region: region ?? this.region,
    primaryDeviceIds: primaryDeviceIds ?? this.primaryDeviceIds,
    secondaryDeviceIds: secondaryDeviceIds ?? this.secondaryDeviceIds,
    exerciseIds: exerciseIds ?? this.exerciseIds,
  );

  factory MuscleGroup.fromJson(Map<String, dynamic> json, String id) =>
      MuscleGroup(
        id: id,
        name: json['name'] as String? ?? '',
        region: MuscleRegion.values.firstWhere(
          (r) => r.name == json['region'],
          orElse: () => MuscleRegion.core,
        ),
        primaryDeviceIds:
            (json['primaryDeviceIds'] as List<dynamic>? ?? [])
                .map((e) => e.toString())
                .toList(),
        secondaryDeviceIds:
            (json['secondaryDeviceIds'] as List<dynamic>? ?? [])
                .map((e) => e.toString())
                .toList(),
        exerciseIds:
            (json['exerciseIds'] as List<dynamic>? ?? [])
                .map((e) => e.toString())
                .toList(),
      );

  Map<String, dynamic> toJson() => {
    'name': name,
    'region': region.name,
    'primaryDeviceIds': primaryDeviceIds,
    'secondaryDeviceIds': secondaryDeviceIds,
    'exerciseIds': exerciseIds,
  };
}
