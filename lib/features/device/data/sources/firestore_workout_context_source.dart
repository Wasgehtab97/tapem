import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tapem/features/device/domain/models/workout_device_xp_state.dart';

abstract class WorkoutContextRemoteSource {
  Future<String> fetchUserNote({
    required String gymId,
    required String deviceId,
    required String userId,
  });

  Future<WorkoutDeviceXpState> fetchUserDeviceXp({
    required String gymId,
    required String deviceId,
    required String userId,
  });
}

class FirestoreWorkoutContextSource implements WorkoutContextRemoteSource {
  FirestoreWorkoutContextSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<String> fetchUserNote({
    required String gymId,
    required String deviceId,
    required String userId,
  }) async {
    final ref = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('devices')
        .doc(deviceId)
        .collection('userNotes')
        .doc(userId);
    try {
      final snapshot = await ref.get().timeout(
        const Duration(milliseconds: 1500),
      );
      return _noteFromSnapshot(snapshot);
    } on FirebaseException {
      final cacheSnap = await ref.get(const GetOptions(source: Source.cache));
      if (cacheSnap.exists) {
        return _noteFromSnapshot(cacheSnap);
      }
      rethrow;
    } on TimeoutException {
      final cacheSnap = await ref.get(const GetOptions(source: Source.cache));
      if (cacheSnap.exists) {
        return _noteFromSnapshot(cacheSnap);
      }
      rethrow;
    }
  }

  @override
  Future<WorkoutDeviceXpState> fetchUserDeviceXp({
    required String gymId,
    required String deviceId,
    required String userId,
  }) async {
    final ref = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('devices')
        .doc(deviceId)
        .collection('leaderboard')
        .doc(userId);
    try {
      final snapshot = await ref.get().timeout(
        const Duration(milliseconds: 1500),
      );
      return _xpFromSnapshot(snapshot);
    } on FirebaseException {
      final cacheSnap = await ref.get(const GetOptions(source: Source.cache));
      if (cacheSnap.exists) {
        return _xpFromSnapshot(cacheSnap);
      }
      rethrow;
    } on TimeoutException {
      final cacheSnap = await ref.get(const GetOptions(source: Source.cache));
      if (cacheSnap.exists) {
        return _xpFromSnapshot(cacheSnap);
      }
      rethrow;
    }
  }

  String _noteFromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    if (!snapshot.exists) {
      return '';
    }
    return (snapshot.data()?['note'] as String? ?? '').trim();
  }

  WorkoutDeviceXpState _xpFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    if (!snapshot.exists) {
      return WorkoutDeviceXpState.initial;
    }
    final data = snapshot.data() ?? const <String, dynamic>{};
    return WorkoutDeviceXpState(
      xp: (data['xp'] as num?)?.toInt() ?? 0,
      level: (data['level'] as num?)?.toInt() ?? 1,
      updatedAt: DateTime.now(),
    );
  }
}
