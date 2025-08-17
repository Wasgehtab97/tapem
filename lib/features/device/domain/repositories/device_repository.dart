// lib/features/device/domain/repositories/device_repository.dart

import '../models/device.dart';
import '../models/device_session_snapshot.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class DeviceRepository {
  Future<List<Device>> getDevicesForGym(String gymId);
  Future<void> createDevice(String gymId, Device device);
  Future<Device?> getDeviceByNfcCode(String gymId, String nfcCode);

  // Neu: Gerät löschen
  Future<void> deleteDevice(String gymId, String deviceId);

  Future<void> updateMuscleGroups(
    String gymId,
    String deviceId,
    List<String> primaryGroups,
    List<String> secondaryGroups,
  );

  Future<void> setMuscleGroups(
    String gymId,
    String deviceId,
    List<String> primaryGroups,
    List<String> secondaryGroups,
  );

  Future<void> writeSessionSnapshot(String gymId, DeviceSessionSnapshot snapshot);

  Future<List<DeviceSessionSnapshot>> fetchSessionSnapshotsPaginated({
    required String gymId,
    required String deviceId,
    required int limit,
    DocumentSnapshot? startAfter,
  });

  Future<DeviceSessionSnapshot?> getSnapshotBySessionId({
    required String gymId,
    required String deviceId,
    required String sessionId,
  });

  DocumentSnapshot? get lastSnapshotCursor;
}
