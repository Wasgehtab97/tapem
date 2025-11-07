import 'package:equatable/equatable.dart';

class WorkoutDeviceSelection extends Equatable {
  const WorkoutDeviceSelection({
    required this.gymId,
    required this.deviceId,
    required this.exerciseId,
  });

  final String gymId;
  final String deviceId;
  final String exerciseId;

  @override
  List<Object?> get props => [gymId, deviceId, exerciseId];
}
