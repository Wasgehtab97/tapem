import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/core/providers/gym_provider.dart';
import 'package:tapem/features/device/domain/models/device.dart';
import 'package:tapem/features/device/domain/models/device_session_snapshot.dart';
import 'package:tapem/features/device/domain/repositories/device_repository.dart';
import 'package:tapem/features/device/domain/usecases/get_devices_for_gym.dart';
import 'package:tapem/features/gym/domain/models/gym_config.dart';
import 'package:tapem/features/gym/domain/repositories/gym_repository.dart';
import 'package:tapem/features/gym/domain/usecases/get_gym_by_id.dart';

void main() {
  group('GymProvider', () {
    test('reset clears devices and reload fetches new gym data', () async {
      final provider = GymProvider(
        getGymById: _FakeGetGymById((id) async => GymConfig(
          id: id,
          code: 'code_$id',
          name: 'Gym $id',
        )),
        getDevicesForGym: _FakeGetDevicesForGym((id) async => [
          Device(uid: '$id-device', id: 1, name: 'Device $id'),
        ]),
      );

      await provider.loadGymData('gymA');
      expect(provider.gym?.name, 'Gym gymA');
      expect(provider.devices.single.uid, 'gymA-device');

      provider.resetGymScopedState();
      expect(provider.gym, isNull);
      expect(provider.devices, isEmpty);

      await provider.loadGymData('gymB');
      expect(provider.gym?.name, 'Gym gymB');
      expect(provider.devices.single.uid, 'gymB-device');
    });
  });
}

class _FakeGetGymById extends GetGymById {
  _FakeGetGymById(this._resolver) : super(_FakeGymRepository());

  final Future<GymConfig> Function(String id) _resolver;

  @override
  Future<GymConfig> execute(String id) => _resolver(id);
}

class _FakeGymRepository implements GymRepository {
  @override
  Future<GymConfig?> getGymByCode(String code) async => null;

  @override
  Future<GymConfig?> getGymById(String id) async => null;
}

class _FakeGetDevicesForGym extends GetDevicesForGym {
  _FakeGetDevicesForGym(this._resolver) : super(_FakeDeviceRepository());

  final Future<List<Device>> Function(String gymId) _resolver;

  @override
  Future<List<Device>> execute(String gymId) => _resolver(gymId);
}

class _FakeDeviceRepository implements DeviceRepository {
  @override
  Future<List<Device>> getDevicesForGym(String gymId) async => const [];

  @override
  Future<void> createDevice(String gymId, Device device) {
    throw UnimplementedError();
  }

  @override
  Future<Device?> getDeviceByNfcCode(String gymId, String nfcCode) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteDevice(String gymId, String deviceId) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateMuscleGroups(
    String gymId,
    String deviceId,
    List<String> primaryGroups,
    List<String> secondaryGroups,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<void> setMuscleGroups(
    String gymId,
    String deviceId,
    List<String> primaryGroups,
    List<String> secondaryGroups,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<void> writeSessionSnapshot(
      String gymId, DeviceSessionSnapshot snapshot) {
    throw UnimplementedError();
  }

  @override
  Future<List<DeviceSessionSnapshot>> fetchSessionSnapshotsPaginated({
    required String gymId,
    required String deviceId,
    required String userId,
    required int limit,
    String? exerciseId,
    DocumentSnapshot? startAfter,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<DeviceSessionSnapshot?> getSnapshotBySessionId({
    required String gymId,
    required String deviceId,
    required String sessionId,
  }) {
    throw UnimplementedError();
  }

  @override
  DocumentSnapshot? get lastSnapshotCursor => null;
}
