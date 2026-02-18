import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapem/features/device/data/dtos/device_dto.dart';
import 'package:tapem/features/device/data/local/device_catalog_cache_store.dart';
import 'package:tapem/features/device/data/sources/firestore_device_source.dart';

class _TestFirestoreDeviceSource extends FirestoreDeviceSource {
  _TestFirestoreDeviceSource({
    required super.firestore,
    required super.cacheStore,
    required this.serverFetch,
    required this.cacheFetch,
  });

  final Future<List<DeviceDto>> Function(String gymId) serverFetch;
  final Future<List<DeviceDto>> Function(String gymId) cacheFetch;

  @override
  Future<List<DeviceDto>> fetchServerDevices(String gymId) {
    return serverFetch(gymId);
  }

  @override
  Future<List<DeviceDto>> fetchFirestoreCachedDevices(String gymId) {
    return cacheFetch(gymId);
  }
}

void main() {
  const cacheStore = DeviceCatalogCacheStore();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test(
    'falls back to local persisted devices when firestore paths fail',
    () async {
      const gymId = 'gym-1';
      final localDevice = DeviceDto(
        uid: 'device-local',
        id: 7,
        name: 'Local Leg Press',
        description: 'cached',
        isMulti: false,
      );
      await cacheStore.writeDevices(gymId, [localDevice]);

      final source = _TestFirestoreDeviceSource(
        firestore: FakeFirebaseFirestore(),
        cacheStore: cacheStore,
        serverFetch: (_) async => throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'unavailable',
        ),
        cacheFetch: (_) async => throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'unavailable',
        ),
      );

      final devices = await source.getDevicesForGym(gymId);
      expect(devices, hasLength(1));
      expect(devices.first.uid, 'device-local');
    },
  );

  test('returns local devices when remote returns empty list', () async {
    const gymId = 'gym-2';
    final localDevice = DeviceDto(
      uid: 'device-cached',
      id: 5,
      name: 'Cached Chest Press',
      description: '',
      isMulti: false,
    );
    await cacheStore.writeDevices(gymId, [localDevice]);

    final source = _TestFirestoreDeviceSource(
      firestore: FakeFirebaseFirestore(),
      cacheStore: cacheStore,
      serverFetch: (_) async => const <DeviceDto>[],
      cacheFetch: (_) async => const <DeviceDto>[],
    );

    final devices = await source.getDevicesForGym(gymId);
    expect(devices.map((d) => d.uid), ['device-cached']);
  });

  test('writes server response back to local cache', () async {
    const gymId = 'gym-3';
    final remoteDevice = DeviceDto(
      uid: 'device-remote',
      id: 1,
      name: 'Remote Device',
      description: 'server',
      isMulti: false,
    );

    final source = _TestFirestoreDeviceSource(
      firestore: FakeFirebaseFirestore(),
      cacheStore: cacheStore,
      serverFetch: (_) async => [remoteDevice],
      cacheFetch: (_) async => const <DeviceDto>[],
    );

    final devices = await source.getDevicesForGym(gymId);
    expect(devices, hasLength(1));
    expect(devices.first.uid, 'device-remote');

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('deviceCatalog/devices/$gymId');
    expect(raw, isNotNull);
    final decoded = jsonDecode(raw!) as List<dynamic>;
    expect(decoded, isNotEmpty);
    final first = decoded.first as Map<String, dynamic>;
    expect(first['uid'], 'device-remote');
  });
}
