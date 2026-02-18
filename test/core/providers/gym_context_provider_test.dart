import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/auth_providers.dart' as auth;
import 'package:tapem/core/providers/gym_context_provider.dart';
import 'package:tapem/core/providers/gym_provider.dart';
import 'package:tapem/features/device/domain/models/device.dart';
import 'package:tapem/features/device/domain/models/device_session_snapshot.dart';
import 'package:tapem/features/device/domain/repositories/device_repository.dart';
import 'package:tapem/features/device/domain/usecases/get_devices_for_gym.dart';
import 'package:tapem/features/gym/domain/models/gym_config.dart';
import 'package:tapem/features/gym/domain/repositories/gym_repository.dart';
import 'package:tapem/features/gym/domain/usecases/get_gym_by_id.dart';

class _FakeGymRepository implements GymRepository {
  _FakeGymRepository(this._gym);

  final GymConfig _gym;

  @override
  Future<GymConfig?> getGymByCode(String code) async => null;

  @override
  Future<GymConfig?> getGymById(String id) async => id == _gym.id ? _gym : null;

  @override
  Future<List<GymConfig>> listGyms() async => [_gym];
}

class _FakeDeviceRepository implements DeviceRepository {
  @override
  Future<List<Device>> getDevicesForGym(String gymId) async => const [];

  @override
  Future<int> allocateNextDeviceId(
    String gymId, {
    required int minimumExistingId,
  }) async => minimumExistingId + 1;

  @override
  Future<void> createDevice(String gymId, Device device) async {}

  @override
  Future<void> updateDevice(String gymId, Device device) async {}

  @override
  Future<void> deleteDevice(String gymId, String deviceId) async {}

  @override
  Future<List<DeviceSessionSnapshot>> fetchSessionSnapshotsPaginated({
    required String gymId,
    required String deviceId,
    required String userId,
    required int limit,
    String? exerciseId,
    DocumentSnapshot? startAfter,
  }) async => const [];

  @override
  Future<Device?> getDeviceByNfcCode(String gymId, String nfcCode) async =>
      null;

  @override
  Future<DeviceSessionSnapshot?> getSnapshotBySessionId({
    required String gymId,
    required String deviceId,
    required String sessionId,
  }) async => null;

  @override
  DocumentSnapshot? get lastSnapshotCursor => null;

  @override
  Future<void> setMuscleGroups(
    String gymId,
    String deviceId,
    List<String> primaryGroups,
    List<String> secondaryGroups,
  ) async {}

  @override
  Future<void> updateMuscleGroups(
    String gymId,
    String deviceId,
    List<String> primaryGroups,
    List<String> secondaryGroups,
  ) async {}

  @override
  Future<void> writeSessionSnapshot(
    String gymId,
    DeviceSessionSnapshot snapshot,
  ) async {}
}

void main() {
  test('gymContextProvider resolves gym context view', () async {
    final gym = GymConfig(id: 'gym-1', code: 'CODE01', name: 'Test Gym');
    final gymProvider = GymProvider(
      getGymById: GetGymById(_FakeGymRepository(gym)),
      getDevicesForGym: GetDevicesForGym(_FakeDeviceRepository()),
    );
    await gymProvider.loadGymData('gym-1');

    final container = ProviderContainer(
      overrides: [
        auth.authViewStateProvider.overrideWithValue(
          const auth.AuthViewState(
            isLoading: false,
            isLoggedIn: true,
            isGuest: false,
            isAdmin: false,
            isCoach: false,
            gymContextStatus: GymContextStatus.ready,
            gymCode: 'gym-1',
            userId: 'user-1',
            error: null,
          ),
        ),
        auth.gymProvider.overrideWith((ref) => gymProvider),
      ],
    );
    addTearDown(container.dispose);

    final view = container.read(gymContextProvider);
    expect(view.isReady, isTrue);
    expect(view.gymId, 'gym-1');
    expect(view.gymName, 'Test Gym');
    expect(view.gym?.id, 'gym-1');
  });
}
