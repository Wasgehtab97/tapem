enum MuscleCategory { upperFront, upperBack, core, lower }

enum MuscleRegion {
  brust(MuscleCategory.upperFront),
  ruecken(MuscleCategory.upperBack),
  schulter(MuscleCategory.upperFront),
  nacken(MuscleCategory.upperBack),
  bizeps(MuscleCategory.upperFront),
  trizeps(MuscleCategory.upperBack),
  bauch(MuscleCategory.core),
  quadrizeps(MuscleCategory.lower),
  hamstrings(MuscleCategory.lower),
  waden(MuscleCategory.lower);

  final MuscleCategory category;
  const MuscleRegion(this.category);
}

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
    this.region = MuscleRegion.bauch,
    List<String>? primaryDeviceIds,
    List<String>? secondaryDeviceIds,
    List<String>? exerciseIds,
  })
      : primaryDeviceIds = List.unmodifiable(primaryDeviceIds ?? []),
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
          orElse: () => MuscleRegion.bauch,
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
    'majorCategory': region.category.name,
    'primaryDeviceIds': primaryDeviceIds,
    'secondaryDeviceIds': secondaryDeviceIds,
    'exerciseIds': exerciseIds,
  };
}
