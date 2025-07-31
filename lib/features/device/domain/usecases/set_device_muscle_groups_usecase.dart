import '../repositories/device_repository.dart';

class SetDeviceMuscleGroupsUseCase {
  final DeviceRepository _repo;
  SetDeviceMuscleGroupsUseCase(this._repo);

  Future<void> execute(
    String gymId,
    String deviceId,
    List<String> primaryGroups,
    List<String> secondaryGroups,
  ) => _repo.setMuscleGroups(gymId, deviceId, primaryGroups, secondaryGroups);
}
