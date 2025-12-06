import 'package:equatable/equatable.dart';

  const WorkoutDeviceSelection({
    required this.gymId,
    required this.deviceId,
    required this.exerciseId,
    this.exerciseName,
  });

  final String gymId;
  final String deviceId;
  final String exerciseId;
  final String? exerciseName;

  @override
  List<Object?> get props => [gymId, deviceId, exerciseId, exerciseName];
}
