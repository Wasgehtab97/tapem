// lib/features/device/data/sources/firestore_exercise_source.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/exercise.dart';
import '../local/device_catalog_cache_store.dart';

class FirestoreExerciseSource {
  final FirebaseFirestore _firestore;
  final DeviceCatalogCacheStore _cacheStore;

  FirestoreExerciseSource({
    FirebaseFirestore? firestore,
    DeviceCatalogCacheStore? cacheStore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _cacheStore = cacheStore ?? const DeviceCatalogCacheStore();

  CollectionReference _col(String gymId, String deviceId) => _firestore
      .collection('gyms')
      .doc(gymId)
      .collection('devices')
      .doc(deviceId)
      .collection('exercises');

  Future<List<Exercise>> fetchServerExercises({
    required String gymId,
    required String deviceId,
    required String userId,
  }) async {
    final snap = await _col(gymId, deviceId)
        .where('userId', isEqualTo: userId)
        .orderBy('name')
        .get()
        .timeout(const Duration(milliseconds: 1500));
    return _mapExercises(snap);
  }

  Future<List<Exercise>> fetchFirestoreCachedExercises({
    required String gymId,
    required String deviceId,
    required String userId,
  }) async {
    final cacheSnap = await _col(gymId, deviceId)
        .where('userId', isEqualTo: userId)
        .orderBy('name')
        .get(const GetOptions(source: Source.cache));
    return _mapExercises(cacheSnap);
  }

  Future<List<Exercise>> getExercises(
    String gymId,
    String deviceId,
    String userId,
  ) async {
    final localCached = await _cacheStore.readExercises(
      gymId: gymId,
      deviceId: deviceId,
      userId: userId,
    );
    try {
      final exercises = await fetchServerExercises(
        gymId: gymId,
        deviceId: deviceId,
        userId: userId,
      );
      if (exercises.isNotEmpty) {
        unawaited(
          _cacheStore.writeExercises(
            gymId: gymId,
            deviceId: deviceId,
            userId: userId,
            exercises: exercises,
          ),
        );
        return exercises;
      }
      if (localCached.isNotEmpty) {
        return localCached;
      }
      return exercises;
    } on FirebaseException {
      final exercises = await _safeFetchFirestoreCachedExercises(
        gymId: gymId,
        deviceId: deviceId,
        userId: userId,
      );
      if (exercises.isNotEmpty) {
        unawaited(
          _cacheStore.writeExercises(
            gymId: gymId,
            deviceId: deviceId,
            userId: userId,
            exercises: exercises,
          ),
        );
        return exercises;
      }
      if (localCached.isNotEmpty) {
        return localCached;
      }
      rethrow;
    } on TimeoutException {
      if (localCached.isNotEmpty) {
        return localCached;
      }
      final exercises = await _safeFetchFirestoreCachedExercises(
        gymId: gymId,
        deviceId: deviceId,
        userId: userId,
      );
      if (exercises.isNotEmpty) {
        unawaited(
          _cacheStore.writeExercises(
            gymId: gymId,
            deviceId: deviceId,
            userId: userId,
            exercises: exercises,
          ),
        );
        return exercises;
      }
      return localCached;
    }
  }

  Future<List<Exercise>> _safeFetchFirestoreCachedExercises({
    required String gymId,
    required String deviceId,
    required String userId,
  }) async {
    try {
      return await fetchFirestoreCachedExercises(
        gymId: gymId,
        deviceId: deviceId,
        userId: userId,
      );
    } on FirebaseException {
      return const <Exercise>[];
    } on TimeoutException {
      return const <Exercise>[];
    }
  }

  List<Exercise> _mapExercises(QuerySnapshot snap) {
    return snap.docs.map((doc) {
      final data = doc.data()! as Map<String, dynamic>;
      return Exercise.fromJson({
        'id': doc.id,
        'name': data['name'] as String,
        'userId': data['userId'] as String,
        'primaryMuscleGroupIds':
            (data['primaryMuscleGroupIds'] as List<dynamic>? ?? [])
                .map((e) => e.toString())
                .toList(),
        'secondaryMuscleGroupIds':
            (data['secondaryMuscleGroupIds'] as List<dynamic>? ?? [])
                .map((e) => e.toString())
                .toList(),
        'muscleGroupIds': (data['muscleGroupIds'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
      });
    }).toList();
  }

  Future<void> createExercise(String gymId, String deviceId, Exercise ex) {
    return _col(gymId, deviceId).doc(ex.id).set(ex.toJson());
  }

  Future<void> updateExercise(String gymId, String deviceId, Exercise ex) {
    return _col(gymId, deviceId).doc(ex.id).update(ex.toJson());
  }

  Future<void> updateMuscleGroups(
    String gymId,
    String deviceId,
    String exId,
    List<String> primary,
    List<String> secondary,
  ) {
    return _col(gymId, deviceId).doc(exId).update({
      'primaryMuscleGroupIds': primary,
      'secondaryMuscleGroupIds': secondary,
    });
  }

  Future<void> deleteExercise(String gymId, String deviceId, String exId) {
    return _col(gymId, deviceId).doc(exId).delete();
  }
}
