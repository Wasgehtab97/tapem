import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapem/features/device/data/dtos/device_dto.dart';
import 'package:tapem/features/device/data/local/device_catalog_cache_store.dart';
import 'package:tapem/features/device/data/repositories/device_repository_impl.dart';
import 'package:tapem/features/device/data/sources/firestore_device_source.dart';
import 'package:tapem/features/device/domain/models/workout_device_xp_state.dart';
import 'package:tapem/features/device/domain/repositories/workout_data_repository.dart';
import 'package:tapem/features/device/domain/usecases/get_devices_for_gym.dart';
import 'package:tapem/features/device/presentation/controllers/workout_day_controller.dart';
import 'package:tapem/features/training_details/domain/repositories/session_repository.dart';
import 'package:tapem/services/membership_service.dart';

class _MockMembershipService extends Mock implements MembershipService {}

class _MockSessionRepository extends Mock implements SessionRepository {}

class _MockWorkoutDataRepository extends Mock
    implements WorkoutDataRepository {}

void main() {
  late _MockMembershipService membership;
  late _MockSessionRepository sessionRepository;
  late _MockWorkoutDataRepository workoutDataRepository;

  setUpAll(() {
    registerFallbackValue(WorkoutDeviceXpState.initial);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    membership = _MockMembershipService();
    sessionRepository = _MockSessionRepository();
    workoutDataRepository = _MockWorkoutDataRepository();

    when(
      () => membership.ensureMembership(any(), any()),
    ).thenAnswer((_) async {});
    when(
      () => workoutDataRepository.getLastSession(
        gymId: any(named: 'gymId'),
        userId: any(named: 'userId'),
        deviceId: any(named: 'deviceId'),
        exerciseId: any(named: 'exerciseId'),
      ),
    ).thenAnswer((_) async => null);
    when(
      () => workoutDataRepository.getUserNote(
        gymId: any(named: 'gymId'),
        deviceId: any(named: 'deviceId'),
        userId: any(named: 'userId'),
      ),
    ).thenAnswer((_) async => '');
    when(
      () => workoutDataRepository.getUserDeviceXp(
        gymId: any(named: 'gymId'),
        deviceId: any(named: 'deviceId'),
        userId: any(named: 'userId'),
      ),
    ).thenAnswer((_) async => WorkoutDeviceXpState.initial);
    when(
      () => workoutDataRepository.cacheUserNote(
        gymId: any(named: 'gymId'),
        deviceId: any(named: 'deviceId'),
        userId: any(named: 'userId'),
        note: any(named: 'note'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => workoutDataRepository.cacheUserDeviceXp(
        gymId: any(named: 'gymId'),
        deviceId: any(named: 'deviceId'),
        userId: any(named: 'userId'),
        stats: any(named: 'stats'),
      ),
    ).thenAnswer((_) async {});
  });

  test('workout day bootstraps device from local catalog cache', () async {
    const cacheStore = DeviceCatalogCacheStore();
    await cacheStore.writeDevices('gym-1', [
      DeviceDto(
        uid: 'device-1',
        id: 1,
        name: 'Cached Leg Press',
        description: 'offline',
        isMulti: false,
      ),
    ]);

    final firestore = FakeFirebaseFirestore();
    final deviceRepository = DeviceRepositoryImpl(
      FirestoreDeviceSource(firestore: firestore, cacheStore: cacheStore),
    );
    final controller = WorkoutDayController(
      firestore: firestore,
      membership: membership,
      sessionRepository: sessionRepository,
      workoutDataRepository: workoutDataRepository,
      getDevicesForGym: GetDevicesForGym(deviceRepository),
    );

    final session = controller.addOrFocusSession(
      gymId: 'gym-1',
      deviceId: 'device-1',
      exerciseId: 'exercise-1',
      userId: 'user-1',
    );
    await session.provider.loadDevice(
      gymId: 'gym-1',
      deviceId: 'device-1',
      exerciseId: 'exercise-1',
      userId: 'user-1',
      forceRefresh: true,
    );

    expect(session.provider.device, isNotNull);
    expect(session.provider.device?.uid, 'device-1');
    expect(session.provider.device?.name, 'Cached Leg Press');
    expect(session.provider.error, isNull);
  });
}
