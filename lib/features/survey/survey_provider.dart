import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'survey.dart';

class SurveyProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore;
  StreamSubscription<List<Survey>>? _openSub;
  StreamSubscription<List<Survey>>? _closedSub;

  List<Survey> openSurveys = [];
  List<Survey> closedSurveys = [];

  SurveyProvider({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  void listen(String gymId) {
    _openSub?.cancel();
    _closedSub?.cancel();

    _openSub = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('surveys')
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => Survey.fromMap(d.id, d.data())).toList(),
        )
        .listen((surveys) {
          openSurveys = surveys;
          notifyListeners();
        });

    _closedSub = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('surveys')
        .where('status', isEqualTo: 'abgeschlossen')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => Survey.fromMap(d.id, d.data())).toList(),
        )
        .listen((surveys) {
          closedSurveys = surveys;
          notifyListeners();
        });
  }

  void cancel() {
    _openSub?.cancel();
    _closedSub?.cancel();
  }

  Future<void> createSurvey({
    required String gymId,
    required String title,
    required List<String> options,
  }) async {
    final doc = {
      'title': title,
      'options': options,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    };
    await _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('surveys')
        .add(doc);
  }

  Future<void> closeSurvey({
    required String gymId,
    required String surveyId,
  }) async {
    await _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('surveys')
        .doc(surveyId)
        .update({'status': 'abgeschlossen'});
  }

  Future<void> submitAnswer({
    required String gymId,
    required String surveyId,
    required String userId,
    required String selectedOption,
  }) async {
    await _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('surveys')
        .doc(surveyId)
        .collection('answers')
        .add({
          'surveyId': surveyId,
          'userId': userId,
          'selectedOption': selectedOption,
          'timestamp': DateTime.now(),
        });
  }

  Future<Map<String, int>> getResults({
    required String gymId,
    required String surveyId,
    required List<String> options,
  }) async {
    final snap =
        await _firestore
            .collection('gyms')
            .doc(gymId)
            .collection('surveys')
            .doc(surveyId)
            .collection('answers')
            .get();
    final Map<String, int> counts = {for (final o in options) o: 0};
    for (final doc in snap.docs) {
      final data = doc.data();
      final opt = data['selectedOption'] as String?;
      if (opt != null && counts.containsKey(opt)) {
        counts[opt] = counts[opt]! + 1;
      }
    }
    return counts;
  }

  @override
  void dispose() {
    cancel();
    super.dispose();
  }
}
