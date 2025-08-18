// lib/features/device/data/repositories/device_repository_impl.dart

import '../dtos/device_dto.dart';
import '../sources/firestore_device_source.dart';
import '../../domain/models/device.dart';
import '../../domain/models/device_session_snapshot.dart';
import '../../domain/repositories/device_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class DeviceRepositoryImpl implements DeviceRepository {
  final FirestoreDeviceSource _source;
  DeviceRepositoryImpl(this._source);

  DocumentSnapshot? _lastSnapshotCursor;

  @override
  DocumentSnapshot? get lastSnapshotCursor => _lastSnapshotCursor;

  @override
  Future<List<Device>> getDevicesForGym(String gymId) async {
    final dtos = await _source.getDevicesForGym(gymId);
    return dtos.map((dto) => dto.toModel()).toList();
  }

  @override
  Future<void> createDevice(String gymId, Device device) {
    return _source.createDevice(gymId, device);
  }

  @override
  Future<Device?> getDeviceByNfcCode(String gymId, String nfcCode) async {
    final all = await getDevicesForGym(gymId);
    try {
      return all.firstWhere((d) => d.nfcCode == nfcCode);
    } catch (_) {
      return null;
    }
  }

  // Neu: Gerät löschen
  @override
  Future<void> deleteDevice(String gymId, String deviceId) {
    return _source.deleteDevice(gymId, deviceId);
  }

  @override
  Future<void> updateMuscleGroups(
    String gymId,
    String deviceId,
    List<String> primaryGroups,
    List<String> secondaryGroups,
  ) {
    return _source.updateMuscleGroups(
      gymId,
      deviceId,
      primaryGroups,
      secondaryGroups,
    );
  }

  @override
  Future<void> setMuscleGroups(
    String gymId,
    String deviceId,
    List<String> primaryGroups,
    List<String> secondaryGroups,
  ) {
    return _source.setMuscleGroups(
      gymId,
      deviceId,
      primaryGroups,
      secondaryGroups,
    );
  }

  @override
  Future<void> writeSessionSnapshot(String gymId, DeviceSessionSnapshot snapshot) {
    return _source.writeSessionSnapshot(gymId, snapshot);
  }

  @override
  Future<List<DeviceSessionSnapshot>> fetchSessionSnapshotsPaginated({
    required String gymId,
    required String deviceId,
    required String userId,
    required int limit,
    DocumentSnapshot? startAfter,
  }) async {
    final snap = await _source.fetchSessionSnapshotsPage(
      gymId: gymId,
      deviceId: deviceId,
      userId: userId,
      limit: limit,
      startAfter: startAfter,
    );

    if (snap.docs.isEmpty && startAfter == null) {
      final legacy = await _source.fetchSessionSnapshotsPage(
        gymId: gymId,
        deviceId: deviceId,
        userId: null,
        limit: limit,
        startAfter: startAfter,
      );
      bool backfilled = false;
      for (final d in legacy.docs) {
        final data = d.data();
        if (data['userId'] == null) {
          backfilled = true;
          d.reference.update({'userId': userId}).catchError((_) {});
        }
      }
      if (backfilled) {
        debugPrint('SNAPSHOT_BACKFILL(userId: set)');
      }
    }

    _lastSnapshotCursor = snap.docs.isNotEmpty ? snap.docs.last : null;
    return snap.docs
        .map((d) => DeviceSessionSnapshot.fromJson(d.data()))
        .toList();
  }

  @override
  Future<DeviceSessionSnapshot?> getSnapshotBySessionId({
    required String gymId,
    required String deviceId,
    required String sessionId,
  }) {
    return _source.getSnapshotBySessionId(
      gymId: gymId,
      deviceId: deviceId,
      sessionId: sessionId,
    );
  }
}
