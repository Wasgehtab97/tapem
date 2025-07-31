import 'dart:math';
import '../models/device.dart';
import '../repositories/device_repository.dart';

class CreateDeviceUseCase {
  final DeviceRepository _repo;
  final Random _random = Random.secure();

  CreateDeviceUseCase(this._repo);

  String _generateNfcCode() {
    final bytes = List<int>.generate(8, (_) => _random.nextInt(256));
    return bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase();
  }

  Future<void> execute({
    required String gymId,
    required Device device,
    required bool isMulti,
    List<String>? muscleGroupIds,
  }) async {
    final existing = await _repo.getDevicesForGym(gymId);
    final maxId =
        existing.isEmpty
            ? 0
            : existing.map((d) => d.id).reduce((a, b) => a > b ? a : b);
    final nextId = maxId + 1;

    final code = _generateNfcCode();
    final toSave = device.copyWith(
      id: nextId,
      nfcCode: code,
      isMulti: isMulti,
      muscleGroupIds: muscleGroupIds,
    );
    await _repo.createDevice(gymId, toSave);
  }
}
