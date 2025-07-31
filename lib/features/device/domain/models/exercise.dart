// lib/features/device/domain/models/exercise.dart
class Exercise {
  final String id;
  final String name;
  final String userId;
  final List<String> muscleGroupIds;

  Exercise({
    required this.id,
    required this.name,
    required this.userId,
    List<String>? muscleGroupIds,
  }) : muscleGroupIds = List.unmodifiable(muscleGroupIds ?? []);

  Exercise copyWith({
    String? id,
    String? name,
    String? userId,
    List<String>? muscleGroupIds,
  }) => Exercise(
    id: id ?? this.id,
    name: name ?? this.name,
    userId: userId ?? this.userId,
    muscleGroupIds: muscleGroupIds ?? this.muscleGroupIds,
  );

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
    id: json['id'] as String,
    name: json['name'] as String,
    userId: json['userId'] as String,
    muscleGroupIds:
        (json['muscleGroupIds'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'userId': userId,
    'muscleGroupIds': muscleGroupIds,
  };
}
