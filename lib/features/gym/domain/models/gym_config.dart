// lib/features/gym/domain/models/gym_config.dart
class GymConfig {
  final String id;
  final String code;
  final String name;

  GymConfig({
    required this.id,
    required this.code,
    required this.name,
  });

  factory GymConfig.fromMap(String id, Map<String, dynamic> data) {
    return GymConfig(
      id: id,
      code: data['code'] as String? ?? '',
      name: data['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
    };
  }
}
