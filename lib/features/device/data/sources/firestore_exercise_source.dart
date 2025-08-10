// lib/features/device/data/sources/firestore_exercise_source.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/exercise.dart';

class FirestoreExerciseSource {
  final FirebaseFirestore _firestore;

  FirestoreExerciseSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference _col(String gymId, String deviceId) => _firestore
      .collection('gyms')
      .doc(gymId)
      .collection('devices')
      .doc(deviceId)
      .collection('exercises');

  Future<List<Exercise>> getExercises(
    String gymId,
    String deviceId,
    String userId,
  ) async {
    final snap =
        await _col(
          gymId,
          deviceId,
        ).where('userId', isEqualTo: userId).orderBy('name').get();

    return snap.docs.map((doc) {
      final data = doc.data()! as Map<String, dynamic>;
      return Exercise.fromJson({
        'id': doc.id,
        'name': data['name'] as String,
        'userId': data['userId'] as String,
        'muscleGroupIds':
            (data['muscleGroupIds'] as List<dynamic>? ?? [])
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

  Future<void> deleteExercise(String gymId, String deviceId, String exId) {
    return _col(gymId, deviceId).doc(exId).delete();
  }
}
