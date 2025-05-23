import 'dart:math';
import 'package:tapem/features/device/domain/models/device.dart';
import 'package:tapem/features/device/domain/repositories/device_repository.dart';

/// UseCase zum Anlegen eines neuen Geräts
/// und gleichzeitiger Vergabe eines 8-Byte (16 Hex-Zeichen) NFC-Codes.
class CreateDeviceUseCase {
  final DeviceRepository _repo;
  final Random _rand = Random.secure();

  CreateDeviceUseCase(this._repo);

  String _generateNfcCode() {
    final bytes = List<int>.generate(8, (_) => _rand.nextInt(256));
    return bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase();
  }

  Future<void> execute(String gymId, Device device) async {
    final code = _generateNfcCode();
    final deviceWithCode = Device(
      id: device.id,
      name: device.name,
      description: device.description,
      nfcCode: code,
    );
    await _repo.createDevice(gymId, deviceWithCode);
  }
}
