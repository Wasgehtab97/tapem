import '../repositories/device_repository.dart';

class UpdateDeviceMuscleGroupsUseCase {
  final DeviceRepository _repo;
  UpdateDeviceMuscleGroupsUseCase(this._repo);

  Future<void> execute(
    String gymId,
    String deviceId,
    List<String> primaryGroups,
    List<String> secondaryGroups,
  ) =>
      _repo.updateMuscleGroups(
        gymId,
        deviceId,
        primaryGroups,
        secondaryGroups,
      );
}
