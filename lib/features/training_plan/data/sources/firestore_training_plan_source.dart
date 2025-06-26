import 'package:cloud_firestore/cloud_firestore.dart';

import '../dtos/training_plan_dto.dart';

class FirestoreTrainingPlanSource {
  final FirebaseFirestore _firestore;

  FirestoreTrainingPlanSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<TrainingPlanDto>> getPlans(String gymId) async {
    final snap =
        await _firestore
            .collection('gyms')
            .doc(gymId)
            .collection('trainingPlans')
            .orderBy('name')
            .get();
    return snap.docs.map((d) => TrainingPlanDto.fromDoc(d)).toList();
  }

  Future<void> savePlan(String gymId, TrainingPlanDto plan) async {
    await _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('trainingPlans')
        .doc(plan.id)
        .set(plan.toMap());
  }
}
