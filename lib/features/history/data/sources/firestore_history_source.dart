// lib/features/history/data/sources/firestore_history_source.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../dtos/workout_log_dto.dart';

/// Liefert alle Workout-Logs für ein Gerät [deviceId] im Gym [gymId] und User [userId].
class FirestoreHistorySource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<WorkoutLogDto>> getLogs(
      String gymId, String deviceId, String userId) async {
    final snapshot = await _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('devices')
        .doc(deviceId)
        .collection('logs')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final dto = WorkoutLogDto.fromDocument(doc);
      return dto;
    }).toList();
  }
}
