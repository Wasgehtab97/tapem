import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tapem/domain/models/training_plan_model.dart';

class FirestoreTrainingPlanSource {
  final FirebaseFirestore _firestore;

  FirestoreTrainingPlanSource([FirebaseFirestore? instance])
      : _firestore = instance ?? FirebaseFirestore.instance;

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> loadPlans(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('training_plans')
        .get()
        .then((snap) => snap.docs);
  }

  Future<String> createPlan(String userId, String name) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('training_plans')
        .add({'name': name, 'createdAt': FieldValue.serverTimestamp()})
        .then((doc) => doc.id);
  }

  Future<void> deletePlan(String userId, String planId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('training_plans')
        .doc(planId)
        .delete();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> loadPlanById(String userId, String planId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('training_plans')
        .doc(planId)
        .get();
  }

  Future<void> startPlan(String userId, String planId) {
    // z.B. ein Feld `active: true` setzen
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('training_plans')
        .doc(planId)
        .update({'active': true});
  }

  Future<void> updatePlan(TrainingPlanModel plan) {
    return _firestore
        .collection('users')
        .doc(plan.id.split('_')[0]) // oder wie Du die userId ableitest
        .collection('training_plans')
        .doc(plan.id)
        .update(plan.toMap());
  }
}
