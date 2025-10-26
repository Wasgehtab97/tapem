import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tapem/features/device/data/dtos/device_dto.dart';
import 'package:tapem/features/device/data/repositories/device_repository_impl.dart';
import 'package:tapem/features/device/data/sources/firestore_device_source.dart';
import 'package:tapem/features/device/domain/models/device.dart';
import 'package:tapem/features/device/domain/models/device_session_snapshot.dart';

class _MockDeviceSource extends Mock implements FirestoreDeviceSource {}

void main() {
  late _MockDeviceSource source;
  late DeviceRepositoryImpl repository;
  late FakeFirebaseFirestore firestore;

  setUp(() {
    source = _MockDeviceSource();
    repository = DeviceRepositoryImpl(source);
    firestore = FakeFirebaseFirestore();
  });

  group('DeviceRepositoryImpl', () {
    test('getDevicesForGym maps DTOs to domain models', () async {
      final dto = DeviceDto(
        uid: 'd1',
        id: 1,
        name: 'Device',
        description: 'Desc',
        isMulti: false,
      );
      when(() => source.getDevicesForGym('gym')).thenAnswer((_) async => [dto]);

      final result = await repository.getDevicesForGym('gym');

      expect(result, hasLength(1));
      expect(result.first.uid, 'd1');
      expect(result.first.name, 'Device');
    });

    test('createDevice delegates to source', () async {
      final device = Device(
        uid: 'd1',
        id: 1,
        name: 'Device',
      );
      when(() => source.createDevice('gym', device)).thenAnswer((_) async {});

      await repository.createDevice('gym', device);

      verify(() => source.createDevice('gym', device)).called(1);
    });

    test('getDeviceByNfcCode returns device when available', () async {
      when(() => source.getDevicesForGym('gym')).thenAnswer((_) async => [
            DeviceDto(
              uid: 'd1',
              id: 1,
              name: 'Device',
              description: '',
              isMulti: false,
              nfcCode: 'CODE',
            ),
          ]);

      final result = await repository.getDeviceByNfcCode('gym', 'CODE');

      expect(result?.nfcCode, 'CODE');
    });

    test('getDeviceByNfcCode returns null when nothing matches', () async {
      when(() => source.getDevicesForGym('gym')).thenAnswer((_) async => []);

      final result = await repository.getDeviceByNfcCode('gym', 'XYZ');

      expect(result, isNull);
    });

    test('deleteDevice delegates to source', () async {
      when(() => source.deleteDevice('gym', 'device')).thenAnswer((_) async {});

      await repository.deleteDevice('gym', 'device');

      verify(() => source.deleteDevice('gym', 'device')).called(1);
    });

    test('updateMuscleGroups delegates to source', () async {
      when(
        () => source.updateMuscleGroups(
          'gym',
          'device',
          ['p1'],
          ['s1'],
        ),
      ).thenAnswer((_) async {});

      await repository.updateMuscleGroups('gym', 'device', ['p1'], ['s1']);

      verify(
        () => source.updateMuscleGroups(
          'gym',
          'device',
          ['p1'],
          ['s1'],
        ),
      ).called(1);
    });

    test('setMuscleGroups delegates to source', () async {
      when(
        () => source.setMuscleGroups(
          'gym',
          'device',
          ['p1'],
          ['s1'],
        ),
      ).thenAnswer((_) async {});

      await repository.setMuscleGroups('gym', 'device', ['p1'], ['s1']);

      verify(
        () => source.setMuscleGroups(
          'gym',
          'device',
          ['p1'],
          ['s1'],
        ),
      ).called(1);
    });

    test('writeSessionSnapshot delegates to source', () async {
      final snapshot = DeviceSessionSnapshot(
        sessionId: 's1',
        deviceId: 'd1',
        createdAt: DateTime(2024, 1, 1),
        userId: 'u1',
        sets: const [],
      );
      when(() => source.writeSessionSnapshot('gym', snapshot))
          .thenAnswer((_) async {});

      await repository.writeSessionSnapshot('gym', snapshot);

      verify(() => source.writeSessionSnapshot('gym', snapshot)).called(1);
    });

    test('fetchSessionSnapshotsPaginated maps snapshots and stores cursor', () async {
      final collection =
          firestore.collection('gyms/gym/devices/device/users/user/sessions');
      await collection.add({
        'sessionId': 's1',
        'deviceId': 'd1',
        'createdAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
        'userId': 'u1',
        'sets': const [],
      });
      final querySnapshot = await collection.get();
      final doc = querySnapshot.docs.first;

      when(
        () => source.fetchSessionSnapshotsPage(
          gymId: 'gym',
          deviceId: 'device',
          userId: 'user',
          exerciseId: null,
          limit: 10,
          startAfter: null,
        ),
      ).thenAnswer((_) async => querySnapshot);

      final results = await repository.fetchSessionSnapshotsPaginated(
        gymId: 'gym',
        deviceId: 'device',
        userId: 'user',
        limit: 10,
      );

      expect(results, hasLength(1));
      expect(results.first.sessionId, 's1');
      expect(repository.lastSnapshotCursor?.id, doc.id);
    });

    test('getSnapshotBySessionId delegates to source', () async {
      final snapshot = DeviceSessionSnapshot(
        sessionId: 's1',
        deviceId: 'd1',
        createdAt: DateTime(2024, 1, 1),
        userId: 'u1',
        sets: const [],
      );
      when(
        () => source.getSnapshotBySessionId(
          gymId: 'gym',
          deviceId: 'device',
          sessionId: 's1',
        ),
      ).thenAnswer((_) async => snapshot);

      final result = await repository.getSnapshotBySessionId(
        gymId: 'gym',
        deviceId: 'device',
        sessionId: 's1',
      );

      expect(result, same(snapshot));
    });
  });
}
