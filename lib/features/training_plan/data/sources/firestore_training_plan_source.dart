import 'package:cloud_firestore/cloud_firestore.dart';

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

  Future<List<TrainingPlanDto>> getPlans(String gymId) async {
    final snap = await _plansCol(gymId).orderBy('name').get();
    final List<TrainingPlanDto> plans = [];
    for (final doc in snap.docs) {
      final weeks = await _loadWeeks(doc.reference);
      plans.add(TrainingPlanDto.fromDoc(doc, weeks: weeks));
    }
    return plans;
  }

  Future<List<WeekBlock>> _loadWeeks(
    DocumentReference<Map<String, dynamic>> planRef,
  ) async {
    final weekSnap =
        await planRef.collection('weeks').orderBy('weekNumber').get();
    final List<WeekBlock> weeks = [];
    for (final weekDoc in weekSnap.docs) {
      final days = await _loadDays(weekDoc.reference);
      weeks.add(
        WeekBlock(
          weekNumber:
              (weekDoc.data()['weekNumber'] as num?)?.toInt() ??
              int.parse(weekDoc.id),
          days: days,
        ),
      );
    }
    return weeks;
  }

  Future<List<DayEntry>> _loadDays(
    DocumentReference<Map<String, dynamic>> weekRef,
  ) async {
    final daySnap = await weekRef.collection('days').orderBy('day').get();
    final List<DayEntry> days = [];
    for (final dayDoc in daySnap.docs) {
      final exSnap = await dayDoc.reference.collection('exercises').get();
      final exercises =
          exSnap.docs.map((e) => ExerciseEntry.fromMap(e.data())).toList();
      days.add(DayEntry(day: dayDoc.id, exercises: exercises));
    }
    return days;
  }

  Future<void> savePlan(String gymId, TrainingPlanDto plan) async {
    final planRef = _plansCol(gymId).doc(plan.id);
    await planRef.set(plan.toMap());

    for (final week in plan.weeks) {
      final weekRef = planRef
          .collection('weeks')
          .doc(week.weekNumber.toString());
      await weekRef.set({'weekNumber': week.weekNumber});
      for (final day in week.days) {
        final dayRef = weekRef.collection('days').doc(day.day);
        await dayRef.set({'day': day.day});
        final exCol = dayRef.collection('exercises');
        for (var i = 0; i < day.exercises.length; i++) {
          final ex = day.exercises[i];
          await exCol.doc('$i').set(ex.toMap());
        }
      }
    }
  }
}
