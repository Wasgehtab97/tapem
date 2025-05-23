// lib/features/device/domain/models/exercise.dart
class Exercise {
  final String id;
  final String name;
  final String userId;

  Exercise({
    required this.id,
    required this.name,
    required this.userId,
  });

  Exercise copyWith({String? id, String? name, String? userId}) =>
    Exercise(
      id:     id     ?? this.id,
      name:   name   ?? this.name,
      userId: userId ?? this.userId,
    );

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
    id:     json['id']     as String,
    name:   json['name']   as String,
    userId: json['userId'] as String,
  );

  Map<String, dynamic> toJson() => {
    'name':   name,
    'userId': userId,
  };
}
