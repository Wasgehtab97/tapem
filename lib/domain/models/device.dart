/// Ein physisches Gerät im Gym (Domain-Modell).
class Device {
  final String id;
  final String name;
  final String exerciseMode;
  final String secretCode;

  const Device({
    required this.id,
    required this.name,
    required this.exerciseMode,
    required this.secretCode,
  });

  factory Device.fromMap(Map<String, dynamic> map, {required String id}) {
    return Device(
      id: id,
      name: map['name'] as String,
      exerciseMode: map['exercise_mode'] as String,
      secretCode: map['secret_code'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'exercise_mode': exerciseMode,
        'secret_code': secretCode,
      };

  @override
  String toString() =>
      'Device(id: $id, name: $name, mode: $exerciseMode)';
}
