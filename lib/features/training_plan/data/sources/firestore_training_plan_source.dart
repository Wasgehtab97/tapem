import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../dtos/training_plan_dto.dart';
import '../../domain/models/week_block.dart';
import '../../domain/models/day_entry.dart';
import '../../domain/models/exercise_entry.dart';

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
    final snap =
        await _plansCol(
          gymId,
        ).where('createdBy', isEqualTo: userId).orderBy('name').get();
    final futures = [
      for (final doc in snap.docs)
        _loadWeeks(
          doc.reference,
        ).then((weeks) => TrainingPlanDto.fromDoc(doc, weeks: weeks)),
    ];
    final plans = await Future.wait(futures);
    debugPrint('ℹ️ Loaded ${plans.length} plans from Firestore');
    return plans;
  }

  Future<List<WeekBlock>> _loadWeeks(
    DocumentReference<Map<String, dynamic>> planRef,
  ) async {
    debugPrint('🔄 _loadWeeks for plan ${planRef.id}');
    final weekSnap =
        await planRef.collection('weeks').orderBy('weekNumber').get();
    final futures = [
      for (final weekDoc in weekSnap.docs)
        _loadDays(weekDoc.reference).then(
          (days) => WeekBlock(
            weekNumber:
                (weekDoc.data()['weekNumber'] as num?)?.toInt() ??
                int.parse(weekDoc.id),
            days: days,
          ),
        ),
    ];
    final weeks = await Future.wait(futures);
    debugPrint('  ↳ loaded ${weeks.length} weeks');
    return weeks;
  }

  Future<List<DayEntry>> _loadDays(
    DocumentReference<Map<String, dynamic>> weekRef,
  ) async {
    debugPrint('  ↪︎ _loadDays for week ${weekRef.id}');
    final daySnap = await weekRef.collection('days').orderBy('date').get();
    final futures = [
      for (final dayDoc in daySnap.docs)
        dayDoc.reference.collection('exercises').get().then((exSnap) {
          final exercises =
              exSnap.docs.map((e) => ExerciseEntry.fromMap(e.data())).toList();
          return DayEntry(
            date: (dayDoc.data()['date'] as Timestamp).toDate(),
            exercises: exercises,
          );
        }),
    ];
    final days = await Future.wait(futures);
    debugPrint('    ↳ loaded ${days.length} days');
    return days;
  }

  Future<void> savePlan(String gymId, TrainingPlanDto plan) async {
    debugPrint('💾 FirestoreTrainingPlanSource.savePlan ${plan.id}');
    final planRef = _plansCol(gymId).doc(plan.id);
    await _deleteExistingWeeks(planRef);
    WriteBatch batch = _firestore.batch();
    int opCount = 0;
    Future<void> commit() async {
      await batch.commit();
      batch = _firestore.batch();
      opCount = 0;
    }

    batch.set(planRef, plan.toMap());
    opCount++;
    for (final week in plan.weeks) {
      debugPrint('  saving week ${week.weekNumber}');
      final weekRef = planRef.collection('weeks').doc(week.weekNumber.toString());
      batch.set(weekRef, {
        'weekNumber': week.weekNumber,
        'createdBy': plan.createdBy,
      });
      if (++opCount > 450) await commit();
      for (final day in week.days) {
        debugPrint('    saving day ${day.date}');
        final id =
            '${day.date.year}-${day.date.month.toString().padLeft(2, '0')}-${day.date.day.toString().padLeft(2, '0')}';
        final dayRef = weekRef.collection('days').doc(id);
        batch.set(dayRef, {
          'date': Timestamp.fromDate(day.date),
          'createdBy': plan.createdBy,
        });
        if (++opCount > 450) await commit();
        final exCol = dayRef.collection('exercises');
        for (var i = 0; i < day.exercises.length; i++) {
          debugPrint(
            '      saving exercise index=$i name=${day.exercises[i].exerciseName}',
          );
          final ex = day.exercises[i];
          final data = ex.toMap();
          data['createdBy'] = plan.createdBy;
          batch.set(exCol.doc('$i'), data);
          if (++opCount > 450) await commit();
        }
      }
    }
    if (opCount > 0) await commit();
  }

  Future<void> renamePlan(String gymId, String planId, String newName) async {
    debugPrint('✏️ Firestore renamePlan $planId -> $newName');
    await _plansCol(gymId).doc(planId).update({'name': newName});
  }

  Future<void> deletePlan(String gymId, String planId) async {
    debugPrint('🗑 Firestore deletePlan $planId');
    await _plansCol(gymId).doc(planId).delete();
  }

  Future<void> deleteExercise(
    String gymId,
    String planId,
    int weekNumber,
    DateTime day,
    int index,
  ) async {
    final dayId =
        '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    final exCol = _plansCol(gymId)
        .doc(planId)
        .collection('weeks')
        .doc('$weekNumber')
        .collection('days')
        .doc(dayId)
        .collection('exercises');
    await exCol.doc('$index').delete();
    final snap = await exCol.orderBy(FieldPath.documentId).get();
    for (var i = 0; i < snap.docs.length; i++) {
      final doc = snap.docs[i];
      if (doc.id != '$i') {
        final data = doc.data();
        await doc.reference.delete();
        await exCol.doc('$i').set(data);
      }
    }
  }

  Future<void> _deleteExistingWeeks(
    DocumentReference<Map<String, dynamic>> planRef,
  ) async {
    final weeks = await planRef.collection('weeks').get();
    WriteBatch batch = _firestore.batch();
    int count = 0;
    Future<void> commit() async {
      await batch.commit();
      batch = _firestore.batch();
      count = 0;
    }

    for (final week in weeks.docs) {
      final days = await week.reference.collection('days').get();
      for (final day in days.docs) {
        final exCol = day.reference.collection('exercises');
        final ex = await exCol.get();
        for (final doc in ex.docs) {
          batch.delete(doc.reference);
          if (++count > 450) await commit();
        }
        batch.delete(day.reference);
        if (++count > 450) await commit();
      }
      batch.delete(week.reference);
      if (++count > 450) await commit();
    }
    if (count > 0) await commit();
  }
}
