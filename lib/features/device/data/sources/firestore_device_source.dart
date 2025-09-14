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

  Future<bool> hasSessionForDate({
    required String gymId,
    required String deviceId,
    required String userId,
    required DateTime date,
  }) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final q = await _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('devices')
        .doc(deviceId)
        .collection('sessions')
        .where('userId', isEqualTo: userId)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThan: Timestamp.fromDate(end))
        .limit(1)
        .get();
    return q.docs.isNotEmpty;
  }
}
