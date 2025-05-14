/// Domain-Modell für ein Gerät im Gym (für Reports).
class DeviceInfo {
  final String id;
  final String name;
  final String exerciseMode;

  const DeviceInfo({
    required this.id,
    required this.name,
    required this.exerciseMode,
  });

  factory DeviceInfo.fromMap(Map<String, dynamic> map, {required String id}) {
    return DeviceInfo(
      id: id,
      name: map['name'] as String,
      exerciseMode: map['exercise_mode'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'exercise_mode': exerciseMode,
      };
}
