// lib/features/device/data/sources/firestore_exercise_source.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/exercise.dart';

class FirestoreExerciseSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _col(String gymId, String deviceId) =>
    _firestore
      .collection('gyms').doc(gymId)
      .collection('devices').doc(deviceId)
      .collection('exercises');

  Future<List<Exercise>> getExercises(String gymId, String deviceId) async {
    final snap = await _col(gymId, deviceId).orderBy('name').get();
    return snap.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return Exercise.fromJson(data);
    }).toList();
  }

  Future<void> createExercise(String gymId, String deviceId, Exercise ex) =>
    _col(gymId, deviceId).doc(ex.id).set(ex.toJson());

  Future<void> deleteExercise(String gymId, String deviceId, String exId) =>
    _col(gymId, deviceId).doc(exId).delete();
}
