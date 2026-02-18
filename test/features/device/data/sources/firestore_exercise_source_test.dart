import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapem/features/device/data/local/device_catalog_cache_store.dart';
import 'package:tapem/features/device/data/sources/firestore_exercise_source.dart';
import 'package:tapem/features/device/domain/models/exercise.dart';

class _TestFirestoreExerciseSource extends FirestoreExerciseSource {
  _TestFirestoreExerciseSource({
    required super.firestore,
    required super.cacheStore,
    required this.serverFetch,
    required this.cacheFetch,
  });

  final Future<List<Exercise>> Function({
    required String gymId,
    required String deviceId,
    required String userId,
  })
  serverFetch;
  final Future<List<Exercise>> Function({
    required String gymId,
    required String deviceId,
    required String userId,
  })
  cacheFetch;

  @override
  Future<List<Exercise>> fetchServerExercises({
    required String gymId,
    required String deviceId,
    required String userId,
  }) {
    return serverFetch(gymId: gymId, deviceId: deviceId, userId: userId);
  }

  @override
  Future<List<Exercise>> fetchFirestoreCachedExercises({
    required String gymId,
    required String deviceId,
    required String userId,
  }) {
    return cacheFetch(gymId: gymId, deviceId: deviceId, userId: userId);
  }
}

void main() {
  const cacheStore = DeviceCatalogCacheStore();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test(
    'falls back to local persisted exercises when firestore paths fail',
    () async {
      const gymId = 'gym-1';
      const deviceId = 'device-1';
      const userId = 'user-1';
      final localExercise = Exercise(
        id: 'exercise-local',
        name: 'Local Squat',
        userId: userId,
      );
      await cacheStore.writeExercises(
        gymId: gymId,
        deviceId: deviceId,
        userId: userId,
        exercises: [localExercise],
      );

      final source = _TestFirestoreExerciseSource(
        firestore: FakeFirebaseFirestore(),
        cacheStore: cacheStore,
        serverFetch:
            ({required gymId, required deviceId, required userId}) async {
              throw FirebaseException(
                plugin: 'cloud_firestore',
                code: 'unavailable',
              );
            },
        cacheFetch:
            ({required gymId, required deviceId, required userId}) async {
              throw FirebaseException(
                plugin: 'cloud_firestore',
                code: 'unavailable',
              );
            },
      );

      final exercises = await source.getExercises(gymId, deviceId, userId);
      expect(exercises, hasLength(1));
      expect(exercises.first.id, 'exercise-local');
    },
  );

  test('returns local exercises when remote returns empty list', () async {
    const gymId = 'gym-2';
    const deviceId = 'device-2';
    const userId = 'user-2';
    final localExercise = Exercise(
      id: 'exercise-cached',
      name: 'Cached Row',
      userId: userId,
    );
    await cacheStore.writeExercises(
      gymId: gymId,
      deviceId: deviceId,
      userId: userId,
      exercises: [localExercise],
    );

    final source = _TestFirestoreExerciseSource(
      firestore: FakeFirebaseFirestore(),
      cacheStore: cacheStore,
      serverFetch:
          ({required gymId, required deviceId, required userId}) async =>
              const <Exercise>[],
      cacheFetch:
          ({required gymId, required deviceId, required userId}) async =>
              const <Exercise>[],
    );

    final exercises = await source.getExercises(gymId, deviceId, userId);
    expect(exercises.map((e) => e.id), ['exercise-cached']);
  });

  test('writes server response back to local cache', () async {
    const gymId = 'gym-3';
    const deviceId = 'device-3';
    const userId = 'user-3';
    final remoteExercise = Exercise(
      id: 'exercise-remote',
      name: 'Remote Press',
      userId: userId,
    );

    final source = _TestFirestoreExerciseSource(
      firestore: FakeFirebaseFirestore(),
      cacheStore: cacheStore,
      serverFetch:
          ({required gymId, required deviceId, required userId}) async =>
              <Exercise>[remoteExercise],
      cacheFetch:
          ({required gymId, required deviceId, required userId}) async =>
              const <Exercise>[],
    );

    final exercises = await source.getExercises(gymId, deviceId, userId);
    expect(exercises, hasLength(1));
    expect(exercises.first.id, 'exercise-remote');

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(
      'deviceCatalog/exercises/$gymId/$deviceId/$userId',
    );
    expect(raw, isNotNull);
    final decoded = jsonDecode(raw!) as List<dynamic>;
    expect(decoded, isNotEmpty);
    final first = decoded.first as Map<String, dynamic>;
    expect(first['id'], 'exercise-remote');
  });
}
