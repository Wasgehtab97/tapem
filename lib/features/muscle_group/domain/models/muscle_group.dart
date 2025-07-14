class MuscleGroup {
  final String id;
  final String name;
  final List<String> deviceIds;

  MuscleGroup({
    required this.id,
    required this.name,
    List<String>? deviceIds,
  }) : deviceIds = List.unmodifiable(deviceIds ?? []);

  MuscleGroup copyWith({
    String? id,
    String? name,
    List<String>? deviceIds,
  }) => MuscleGroup(
        id: id ?? this.id,
        name: name ?? this.name,
        deviceIds: deviceIds ?? this.deviceIds,
      );

  factory MuscleGroup.fromJson(Map<String, dynamic> json, String id) => MuscleGroup(
        id: id,
        name: json['name'] as String? ?? '',
        deviceIds: (json['deviceIds'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'deviceIds': deviceIds,
      };
}
