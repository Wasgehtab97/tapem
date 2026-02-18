// lib/features/device/data/sources/firestore_device_source.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/device.dart';
import '../../domain/models/device_session_snapshot.dart';
import '../local/device_catalog_cache_store.dart';
import '../dtos/device_dto.dart';

class FirestoreDeviceSource {
  final FirebaseFirestore _firestore;
  final DeviceCatalogCacheStore _cacheStore;

  FirestoreDeviceSource({
    FirebaseFirestore? firestore,
    DeviceCatalogCacheStore? cacheStore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _cacheStore = cacheStore ?? const DeviceCatalogCacheStore();

  Future<List<DeviceDto>> fetchServerDevices(String gymId) async {
    final snap = await _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('devices')
        .orderBy('id')
        .get()
        .timeout(const Duration(milliseconds: 1500));
    return snap.docs.map((doc) => DeviceDto.fromDocument(doc)).toList();
  }

  Future<List<DeviceDto>> fetchFirestoreCachedDevices(String gymId) async {
    final cacheSnap = await _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('devices')
        .orderBy('id')
        .get(const GetOptions(source: Source.cache));
    return cacheSnap.docs.map((doc) => DeviceDto.fromDocument(doc)).toList();
  }

  Future<List<DeviceDto>> getDevicesForGym(String gymId) async {
    final localCached = await _cacheStore.readDevices(gymId);
    try {
      final devices = await fetchServerDevices(gymId);
      if (devices.isNotEmpty) {
        unawaited(_cacheStore.writeDevices(gymId, devices));
        return devices;
      }
      if (localCached.isNotEmpty) {
        return localCached;
      }
      return devices;
    } on FirebaseException {
      final cachedDevices = await _safeFetchFirestoreCachedDevices(gymId);
      if (cachedDevices.isNotEmpty) {
        unawaited(_cacheStore.writeDevices(gymId, cachedDevices));
        return cachedDevices;
      }
      if (localCached.isNotEmpty) {
        return localCached;
      }
      rethrow;
    } on TimeoutException {
      if (localCached.isNotEmpty) {
        return localCached;
      }
      final cachedDevices = await _safeFetchFirestoreCachedDevices(gymId);
      if (cachedDevices.isNotEmpty) {
        unawaited(_cacheStore.writeDevices(gymId, cachedDevices));
        return cachedDevices;
      }
      return localCached;
    }
  }

  Future<List<DeviceDto>> _safeFetchFirestoreCachedDevices(String gymId) async {
    try {
      return await fetchFirestoreCachedDevices(gymId);
    } on FirebaseException {
      return const <DeviceDto>[];
    } on TimeoutException {
      return const <DeviceDto>[];
    }
  }

  Future<int> allocateNextDeviceId(
    String gymId, {
    required int minimumExistingId,
  }) {
    final gymRef = _firestore.collection('gyms').doc(gymId);
    return _firestore.runTransaction((tx) async {
      final gymSnap = await tx.get(gymRef);
      final data = gymSnap.data() ?? const <String, dynamic>{};
      final rawCounter = data['deviceNumberCounter'];
      final currentCounter = rawCounter is int ? rawCounter : 0;
      final baseline = minimumExistingId > currentCounter
          ? minimumExistingId
          : currentCounter;
      final nextId = baseline + 1;
      tx.set(gymRef, {
        'deviceNumberCounter': nextId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return nextId;
    });
  }

  Future<void> createDevice(String gymId, Device device) {
    return _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('devices')
        .doc(device.uid)
        .set(device.toJson());
  }

  Future<void> updateDevice(String gymId, Device device) {
    return _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('devices')
        .doc(device.uid)
        .update(device.toJson());
  }

  // Neu: Gerät löschen
  Future<void> deleteDevice(String gymId, String deviceId) {
    return _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('devices')
        .doc(deviceId)
        .delete();
  }

  Future<void> updateMuscleGroups(
    String gymId,
    String deviceId,
    List<String> primaryGroups,
    List<String> secondaryGroups,
  ) {
    final ref = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('devices')
        .doc(deviceId);
    final all = [...primaryGroups, ...secondaryGroups];
    final data = <String, dynamic>{};
    if (primaryGroups.isNotEmpty) {
      data['primaryMuscleGroups'] = FieldValue.arrayUnion(primaryGroups);
    }
    if (secondaryGroups.isNotEmpty) {
      data['secondaryMuscleGroups'] = FieldValue.arrayUnion(secondaryGroups);
    }
    if (all.isNotEmpty) {
      data['muscleGroups'] = FieldValue.arrayUnion(all);
    }
    return ref.update(data);
  }

  Future<void> setMuscleGroups(
    String gymId,
    String deviceId,
    List<String> primaryGroups,
    List<String> secondaryGroups,
  ) {
    final ref = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('devices')
        .doc(deviceId);
    final all = [...primaryGroups, ...secondaryGroups];
    return ref.update({
      'primaryMuscleGroups': primaryGroups,
      'secondaryMuscleGroups': secondaryGroups,
      'muscleGroups': all,
      'muscleGroupIds': all,
    });
  }

  Future<void> writeSessionSnapshot(
    String gymId,
    DeviceSessionSnapshot snapshot,
  ) {
    final ref = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('devices')
        .doc(snapshot.deviceId)
        .collection('sessions')
        .doc(snapshot.sessionId);
    final data = snapshot.toJson();
    data['createdAt'] = FieldValue.serverTimestamp();
    return ref.set(data);
  }

  Future<QuerySnapshot<Map<String, dynamic>>> fetchSessionSnapshotsPage({
    required String gymId,
    required String deviceId,
    required String? userId,
    String? exerciseId,
    int limit = 10,
    DocumentSnapshot? startAfter,
  }) {
    Query<Map<String, dynamic>> q = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('devices')
        .doc(deviceId)
        .collection('sessions');

    if (userId != null) {
      q = q.where('userId', isEqualTo: userId);
    }

    if (exerciseId != null) {
      q = q.where('exerciseId', isEqualTo: exerciseId);
    }

    q = q.orderBy('createdAt', descending: true).limit(limit);
    if (startAfter != null) {
      q = q.startAfterDocument(startAfter);
    }
    return q.get();
  }

  Future<DeviceSessionSnapshot?> getSnapshotBySessionId({
    required String gymId,
    required String deviceId,
    required String sessionId,
  }) async {
    final ref = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('devices')
        .doc(deviceId)
        .collection('sessions')
        .doc(sessionId);
    final snap = await ref.get();
    if (!snap.exists) return null;
    return DeviceSessionSnapshot.fromJson(snap.data()!);
  }

  Future<void> deleteSessionSnapshot({
    required String gymId,
    required String deviceId,
    required String sessionId,
  }) async {
    final ref = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('devices')
        .doc(deviceId)
        .collection('sessions')
        .doc(sessionId);
    await ref.delete();
  }
}
