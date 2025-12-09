import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tapem/features/training_plan/domain/models/training_plan.dart';
import 'package:tapem/features/training_plan/domain/models/training_plan_exercise.dart';
import 'package:tapem/features/training_plan/domain/models/training_plan_stats.dart';

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

  DocumentReference<Map<String, dynamic>> _statsDoc(
    String userId,
    String planId,
  ) {
    return _userPlans(userId)
        .doc(planId)
        .collection('meta')
        .doc('stats');
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
    await _statsDoc(userId, planId).delete().catchError((_) {});
  }

  Future<TrainingPlanStats> getStats({
    required String userId,
    required String planId,
  }) async {
    final snap = await _statsDoc(userId, planId).get();
    if (!snap.exists) {
      return TrainingPlanStats.empty();
    }
    final data = snap.data() ?? {};
    if (data['firstCompletedAt'] is Timestamp) {
      data['firstCompletedAt'] =
          (data['firstCompletedAt'] as Timestamp).toDate().toIso8601String();
    }
    if (data['lastCompletedAt'] is Timestamp) {
      data['lastCompletedAt'] =
          (data['lastCompletedAt'] as Timestamp).toDate().toIso8601String();
    }
    return TrainingPlanStats.fromJson(data);
  }

  Future<void> incrementCompletion({
    required String userId,
    required String planId,
  }) async {
    final doc = _statsDoc(userId, planId);
    await _firestore.runTransaction((trx) async {
      final snap = await trx.get(doc);
      final now = DateTime.now();
      if (!snap.exists) {
        trx.set(doc, {
          'completions': 1,
          'firstCompletedAt': Timestamp.fromDate(now),
          'lastCompletedAt': Timestamp.fromDate(now),
        });
        return;
      }
      final data = snap.data() ?? {};
      final completions = (data['completions'] as int? ?? 0) + 1;
      final firstCompletedAt = data['firstCompletedAt'] is Timestamp
          ? data['firstCompletedAt'] as Timestamp
          : Timestamp.fromDate(now);
      trx.update(doc, {
        'completions': completions,
        'firstCompletedAt': firstCompletedAt,
        'lastCompletedAt': Timestamp.fromDate(now),
      });
    });
  }
}
