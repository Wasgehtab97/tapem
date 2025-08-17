// lib/features/device/data/sources/firestore_device_source.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/device.dart';
import '../../domain/models/device_session_snapshot.dart';
import '../dtos/device_dto.dart';

class FirestoreDeviceSource {
  final FirebaseFirestore _firestore;

  FirestoreDeviceSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<DeviceDto>> getDevicesForGym(String gymId) async {
    final snap = await _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('devices')
        .orderBy('id')
        .get();
    return snap.docs.map((doc) => DeviceDto.fromDocument(doc)).toList();
  }

  Future<void> createDevice(String gymId, Device device) {
    return _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('devices')
        .doc(device.uid)
        .set(device.toJson());
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

  Future<void> writeSessionSnapshot(String gymId, DeviceSessionSnapshot snapshot) {
    final ref = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('devices')
        .doc(snapshot.deviceId)
        .collection('sessions')
        .doc(snapshot.sessionId);
    return ref.set(snapshot.toJson());
  }

  Future<List<DeviceSessionSnapshot>> fetchSessionSnapshotsPaginated({
    required String gymId,
    required String deviceId,
    required int limit,
    DocumentSnapshot? startAfter,
  }) async {
    Query q = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('devices')
        .doc(deviceId)
        .collection('sessions')
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (startAfter != null) {
      q = q.startAfterDocument(startAfter);
    }
    final snap = await q.get();
    return snap.docs
        .map((d) => DeviceSessionSnapshot.fromJson(d.data() as Map<String, dynamic>))
        .toList();
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
}
