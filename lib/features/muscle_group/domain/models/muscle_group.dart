enum MuscleRegion { chest, back, shoulders, arms, core, legs }

class MuscleGroup {
  final String id;
  final String name;
  final MuscleRegion region;
  final List<String> deviceIds;

  MuscleGroup({
    required this.id,
    required this.name,
    this.region = MuscleRegion.core,
    List<String>? deviceIds,
  }) : deviceIds = List.unmodifiable(deviceIds ?? []);

  MuscleGroup copyWith({
    String? id,
    String? name,
    MuscleRegion? region,
    List<String>? deviceIds,
  }) => MuscleGroup(
        id: id ?? this.id,
        name: name ?? this.name,
        region: region ?? this.region,
        deviceIds: deviceIds ?? this.deviceIds,
      );

  factory MuscleGroup.fromJson(Map<String, dynamic> json, String id) => MuscleGroup(
        id: id,
        name: json['name'] as String? ?? '',
        region: MuscleRegion.values.firstWhere(
          (r) => r.name == json['region'],
          orElse: () => MuscleRegion.core,
        ),
        deviceIds: (json['deviceIds'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'region': region.name,
        'deviceIds': deviceIds,
      };
}
