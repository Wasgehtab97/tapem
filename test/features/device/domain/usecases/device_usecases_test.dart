import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tapem/features/device/domain/models/device.dart';
import 'package:tapem/features/device/domain/repositories/device_repository.dart';
import 'package:tapem/features/device/domain/usecases/create_device_usecase.dart';
import 'package:tapem/features/device/domain/usecases/delete_device_usecase.dart';
import 'package:tapem/features/device/domain/usecases/get_device_by_nfc_code.dart';
import 'package:tapem/features/device/domain/usecases/get_devices_for_gym.dart';
import 'package:tapem/features/device/domain/usecases/set_device_muscle_groups_usecase.dart';
import 'package:tapem/features/device/domain/usecases/update_device_muscle_groups_usecase.dart';

class _MockDeviceRepository extends Mock implements DeviceRepository {}

class _FakeDevice extends Fake implements Device {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeDevice());
  });

  group('Device use cases', () {
    late _MockDeviceRepository repo;

    setUp(() {
      repo = _MockDeviceRepository();
    });

    test('CreateDeviceUseCase generates incremented id and delegates creation', () async {
      final existing = [
        Device(uid: 'a', id: 1, name: 'A'),
        Device(uid: 'b', id: 5, name: 'B'),
      ];
      when(() => repo.getDevicesForGym('gym')).thenAnswer((_) async => existing);
      when(() => repo.createDevice(any(), any())).thenAnswer((_) async {});

      final useCase = CreateDeviceUseCase(repo);
      final baseDevice = Device(uid: 'new', id: 0, name: 'New');

      await useCase.execute(
        gymId: 'gym',
        device: baseDevice,
        isMulti: true,
        muscleGroupIds: const ['legs'],
      );

      final captured = verify(() => repo.createDevice('gym', captureAny())).captured.single as Device;
      expect(captured.id, 6);
      expect(captured.isMulti, isTrue);
      expect(captured.muscleGroupIds, ['legs']);
      expect(captured.nfcCode, isNotEmpty);
    });

    test('DeleteDeviceUseCase forwards to repository', () async {
      when(() => repo.deleteDevice('gym', 'device')).thenAnswer((_) async {});
      final useCase = DeleteDeviceUseCase(repo);

      await useCase.execute(gymId: 'gym', deviceId: 'device');

      verify(() => repo.deleteDevice('gym', 'device')).called(1);
    });

    test('GetDevicesForGym forwards to repository', () async {
      when(() => repo.getDevicesForGym('gym')).thenAnswer((_) async => []);
      final useCase = GetDevicesForGym(repo);

      await useCase.execute('gym');

      verify(() => repo.getDevicesForGym('gym')).called(1);
    });

    test('GetDeviceByNfcCode forwards to repository', () async {
      when(() => repo.getDeviceByNfcCode('gym', 'code')).thenAnswer((_) async => null);
      final useCase = GetDeviceByNfcCode(repo);

      await useCase.execute('gym', 'code');

      verify(() => repo.getDeviceByNfcCode('gym', 'code')).called(1);
    });

    test('UpdateDeviceMuscleGroupsUseCase forwards to repository', () async {
      when(
        () => repo.updateMuscleGroups('gym', 'device', ['p'], ['s']),
      ).thenAnswer((_) async {});
      final useCase = UpdateDeviceMuscleGroupsUseCase(repo);

      await useCase.execute('gym', 'device', ['p'], ['s']);

      verify(() => repo.updateMuscleGroups('gym', 'device', ['p'], ['s'])).called(1);
    });

    test('SetDeviceMuscleGroupsUseCase forwards to repository', () async {
      when(
        () => repo.setMuscleGroups('gym', 'device', ['p'], ['s']),
      ).thenAnswer((_) async {});
      final useCase = SetDeviceMuscleGroupsUseCase(repo);

      await useCase.execute('gym', 'device', ['p'], ['s']);

      verify(() => repo.setMuscleGroups('gym', 'device', ['p'], ['s'])).called(1);
    });
  });
}
