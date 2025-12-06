import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tapem/features/training_plan/domain/models/training_plan.dart';
import 'package:tapem/features/training_plan/domain/models/training_plan_exercise.dart';

class FirestoreTrainingPlanSource {
  final FirebaseFirestore _firestore;

  FirestoreTrainingPlanSource([FirebaseFirestore? instance])
      : _firestore = instance ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _userPlans(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('training_plans');
  }

  Future<List<TrainingPlan>> getPlans({
    required String gymId,
    required String userId,
  }) async {
    final snapshot = await _userPlans(userId)
        .where('gymId', isEqualTo: gymId)
        .orderBy('updatedAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id; // Ensure ID is part of data
      
      // Handle timestamp conversion if needed (Firestore Timestamp to String for compatibility)
      // Assuming Request is to follow strict JSON model from earlier, but here we can clean up
      if (data['createdAt'] is Timestamp) {
        data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
      }
      if (data['updatedAt'] is Timestamp) {
        data['updatedAt'] = (data['updatedAt'] as Timestamp).toDate().toIso8601String();
      }
      
      return TrainingPlan.fromJson(data);
    }).toList();
  }

  Future<void> savePlan({
    required String userId,
    required TrainingPlan plan,
  }) async {
    final docRef = _userPlans(userId).doc(plan.id);
    
    // Convert to Firestore compatible map (using Timestamps)
    final json = plan.toJson();
    json['createdAt'] = Timestamp.fromDate(plan.createdAt);
    json['updatedAt'] = Timestamp.fromDate(plan.updatedAt);
    // ID is the doc ID, no need to duplicate? But good for consistency
    
    await docRef.set(json, SetOptions(merge: true));
  }

  Future<void> deletePlan({
    required String userId,
    required String planId,
  }) async {
    await _userPlans(userId).doc(planId).delete();
  }
}
