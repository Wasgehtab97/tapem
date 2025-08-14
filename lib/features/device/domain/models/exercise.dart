// lib/features/device/domain/models/exercise.dart
class Exercise {
  final String id;
  final String name;
  final String userId;
  final List<String> primaryMuscleGroupIds;
  final List<String> secondaryMuscleGroupIds;
  final List<String> muscleGroupIds;

  Exercise({
    required this.id,
    required this.name,
    required this.userId,
    List<String>? primaryMuscleGroupIds,
    List<String>? secondaryMuscleGroupIds,
  })  : primaryMuscleGroupIds =
            List.unmodifiable(primaryMuscleGroupIds ?? []),
        secondaryMuscleGroupIds =
            List.unmodifiable(secondaryMuscleGroupIds ?? []),
        muscleGroupIds = List.unmodifiable([
          ...(primaryMuscleGroupIds ?? []),
          ...(secondaryMuscleGroupIds ?? []),
        ]);

  Exercise copyWith({
    String? id,
    String? name,
    String? userId,
    List<String>? primaryMuscleGroupIds,
    List<String>? secondaryMuscleGroupIds,
  }) =>
      Exercise(
        id: id ?? this.id,
        name: name ?? this.name,
        userId: userId ?? this.userId,
        primaryMuscleGroupIds:
            primaryMuscleGroupIds ?? this.primaryMuscleGroupIds,
        secondaryMuscleGroupIds:
            secondaryMuscleGroupIds ?? this.secondaryMuscleGroupIds,
      );

  factory Exercise.fromJson(Map<String, dynamic> json) {
    final primary = (json['primaryMuscleGroupIds'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    final secondary = (json['secondaryMuscleGroupIds'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    if (primary.isEmpty && secondary.isEmpty) {
      primary.addAll(
        (json['muscleGroupIds'] as List<dynamic>? ?? [])
            .map((e) => e.toString()),
      );
    }
    return Exercise(
      id: json['id'] as String,
      name: json['name'] as String,
      userId: json['userId'] as String,
      primaryMuscleGroupIds: primary,
      secondaryMuscleGroupIds: secondary,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'userId': userId,
        'primaryMuscleGroupIds': primaryMuscleGroupIds,
        'secondaryMuscleGroupIds': secondaryMuscleGroupIds,
      };
}
