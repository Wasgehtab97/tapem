enum MuscleCategory { upperFront, upperBack, core, lower }

enum MuscleRegion {
  chest(MuscleCategory.upperFront),
  anteriorDeltoid(MuscleCategory.upperFront),
  biceps(MuscleCategory.upperFront),
  wristFlexors(MuscleCategory.upperFront),
  lats(MuscleCategory.upperBack),
  midBack(MuscleCategory.upperBack),
  posteriorDeltoid(MuscleCategory.upperBack),
  upperTrapezius(MuscleCategory.upperBack),
  triceps(MuscleCategory.upperBack),
  rectusAbdominis(MuscleCategory.core),
  obliques(MuscleCategory.core),
  transversusAbdominis(MuscleCategory.core),
  quadriceps(MuscleCategory.lower),
  hamstrings(MuscleCategory.lower),
  glutes(MuscleCategory.lower),
  adductors(MuscleCategory.lower),
  abductors(MuscleCategory.lower),
  calves(MuscleCategory.lower),
  tibialisAnterior(MuscleCategory.lower);

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
    this.region = MuscleRegion.rectusAbdominis,
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
          orElse: () => MuscleRegion.rectusAbdominis,
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
