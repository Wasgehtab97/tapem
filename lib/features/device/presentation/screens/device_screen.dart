import 'package:flutter/widgets.dart';

import 'workout_day_screen.dart';

class DeviceScreen extends StatelessWidget {
  final String gymId;
  final String deviceId;
  final String exerciseId;

  const DeviceScreen({
    super.key,
    required this.gymId,
    required this.deviceId,
    required this.exerciseId,
  });

  @override
  Widget build(BuildContext context) {
    return WorkoutDayScreen(
      gymId: gymId,
      deviceId: deviceId,
      exerciseId: exerciseId,
    );
  }
}
