import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tapem/features/device/domain/models/exercise.dart';
import 'package:tapem/features/device/providers/device_riverpod.dart';

class DeviceExercisePreviewKey {
  const DeviceExercisePreviewKey({
    required this.gymId,
    required this.deviceId,
    required this.userId,
  });

  final String gymId;
  final String deviceId;
  final String userId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeviceExercisePreviewKey &&
        other.gymId == gymId &&
        other.deviceId == deviceId &&
        other.userId == userId;
  }

  @override
  int get hashCode => Object.hash(gymId, deviceId, userId);
}

final deviceExercisePreviewProvider = FutureProvider.autoDispose
    .family<List<Exercise>, DeviceExercisePreviewKey>((ref, key) async {
      final getExercisesForDevice = ref.watch(getExercisesForDeviceProvider);
      return getExercisesForDevice.execute(key.gymId, key.deviceId, key.userId);
    });
