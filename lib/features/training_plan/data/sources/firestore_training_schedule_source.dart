import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:tapem/features/training_plan/domain/models/training_day_assignment.dart';

class FirestoreTrainingScheduleSource {
  FirestoreTrainingScheduleSource([FirebaseFirestore? instance])
      : _firestore = instance ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(
    String userId,
    String dateKey,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('training_schedule')
        .doc(dateKey);
  }

  Future<TrainingDayAssignment?> getAssignment({
    required String userId,
    required String dateKey,
  }) async {
    final snap = await _doc(userId, dateKey).get();
    if (!snap.exists) {
      return null;
    }
    final data = snap.data() ?? {};
    data['dateKey'] = dateKey;
    final planId = data['planId'];
    if (planId is! String || planId.isEmpty) {
      return null;
    }
    return TrainingDayAssignment.fromJson(data);
  }

  Future<void> setAssignment({
    required String userId,
    required String dateKey,
    required String planId,
  }) async {
    final now = DateTime.now();
    await _doc(userId, dateKey).set(
      {
        'dateKey': dateKey,
        'planId': planId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> clearAssignment({
    required String userId,
    required String dateKey,
  }) async {
    await _doc(userId, dateKey).delete();
  }

  Future<List<TrainingDayAssignment>> getAssignmentsForYear({
    required String userId,
    required int year,
  }) async {
    final startKey =
        '$year-01-01'; // lexikographische Sortierung passt zum Datumsformat
    final endKey = '$year-12-31';
    final snap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('training_schedule')
        .where('dateKey', isGreaterThanOrEqualTo: startKey)
        .where('dateKey', isLessThanOrEqualTo: endKey)
        .get();
    return snap.docs.map((doc) {
      final data = doc.data();
      data['dateKey'] = data['dateKey'] ?? doc.id;
      return TrainingDayAssignment.fromJson(data);
    }).toList();
  }
}
