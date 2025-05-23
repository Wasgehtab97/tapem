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
  }) async {
    final code   = _generateNfcCode();
    final toSave = device.copyWith(nfcCode: code, isMulti: isMulti);
    await _repo.createDevice(gymId, toSave);
  }
}
