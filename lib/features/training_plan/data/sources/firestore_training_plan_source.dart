import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../dtos/training_plan_dto.dart';

class FirestoreTrainingPlanSource {
  final FirebaseFirestore _firestore;

  FirestoreTrainingPlanSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _plansCol(String gymId) =>
      _firestore.collection('gyms').doc(gymId).collection('trainingPlans');

  Future<List<TrainingPlanDto>> getPlans(String gymId, String userId) async {
    debugPrint(
      '📡 FirestoreTrainingPlanSource.getPlans gymId=$gymId userId=$userId',
    );
    final snap = await _plansCol(gymId)
        .where('createdBy', isEqualTo: userId)
        .orderBy('name')
        .get();
    final plans = snap.docs.map(TrainingPlanDto.fromDoc).toList();
    debugPrint('ℹ️ Loaded ${plans.length} plans from Firestore');
    return plans;
  }

  Future<void> savePlan(String gymId, TrainingPlanDto plan) async {
    debugPrint('💾 FirestoreTrainingPlanSource.savePlan ${plan.id}');
    final planRef = _plansCol(gymId).doc(plan.id);
    await planRef.set(plan.toMap());
  }

  Future<void> renamePlan(String gymId, String planId, String newName) async {
    debugPrint('✏️ Firestore renamePlan $planId -> $newName');
    await _plansCol(gymId).doc(planId).update({'name': newName});
  }

  Future<void> deletePlan(String gymId, String planId) async {
    debugPrint('🗑 Firestore deletePlan $planId');
    await _plansCol(gymId).doc(planId).delete();
  }
}
