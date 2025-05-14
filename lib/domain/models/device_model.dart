/// Domain-Modell für ein physisches Gerät im Gym.
class DeviceModel {
  final String documentId;
  final String name;
  final String exerciseMode;
  final String secretCode;

  const DeviceModel({
    required this.documentId,
    required this.name,
    required this.exerciseMode,
    required this.secretCode,
  });

  factory DeviceModel.fromMap(
    Map<String, dynamic> map, {
    required String documentId,
  }) {
    return DeviceModel(
      documentId: documentId,
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
      'DeviceModel(id: $documentId, name: $name, mode: $exerciseMode)';
}
