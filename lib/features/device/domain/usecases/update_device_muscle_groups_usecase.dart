import '../repositories/device_repository.dart';

class UpdateDeviceMuscleGroupsUseCase {
  final DeviceRepository _repo;
  UpdateDeviceMuscleGroupsUseCase(this._repo);

  Future<void> execute(
    String gymId,
    String deviceId,
    List<String> groups,
  ) => _repo.updateMuscleGroups(gymId, deviceId, groups);
}
