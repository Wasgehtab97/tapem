import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:tapem/features/survey/survey_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SurveyProvider', () {
    test('createSurvey adds document', () async {
      final firestore = FakeFirebaseFirestore();
      final provider = SurveyProvider(firestore: firestore);
      await provider.createSurvey(
        gymId: 'g1',
        title: 'Test',
        options: const ['A', 'B'],
      );
      final snap = await firestore
          .collection('gyms')
          .doc('g1')
          .collection('surveys')
          .get();
      expect(snap.docs.length, 1);
    });

    test('submitAnswer stores response', () async {
      final firestore = FakeFirebaseFirestore();
      final provider = SurveyProvider(firestore: firestore);
      final surveyRef = await firestore
          .collection('gyms')
          .doc('g1')
          .collection('surveys')
          .add({
            'title': 'T',
            'options': ['A', 'B'],
            'status': 'open',
            'createdAt': Timestamp.now(),
          });
      await provider.submitAnswer(
        gymId: 'g1',
        surveyId: surveyRef.id,
        userId: 'u1',
        selectedOption: 'A',
      );
      final snap = await surveyRef.collection('answers').get();
      expect(snap.docs.length, 1);
    });

    test('getResults counts votes', () async {
      final firestore = FakeFirebaseFirestore();
      final provider = SurveyProvider(firestore: firestore);
      final surveyRef = await firestore
          .collection('gyms')
          .doc('g1')
          .collection('surveys')
          .add({
            'title': 'T',
            'options': ['A', 'B'],
            'status': 'open',
            'createdAt': Timestamp.now(),
          });
      await surveyRef.collection('answers').add({
        'surveyId': surveyRef.id,
        'userId': 'u1',
        'selectedOption': 'A',
        'timestamp': Timestamp.now(),
      });
      await surveyRef.collection('answers').add({
        'surveyId': surveyRef.id,
        'userId': 'u2',
        'selectedOption': 'B',
        'timestamp': Timestamp.now(),
      });
      await surveyRef.collection('answers').add({
        'surveyId': surveyRef.id,
        'userId': 'u3',
        'selectedOption': 'A',
        'timestamp': Timestamp.now(),
      });
      final results = await provider.getResults(
        gymId: 'g1',
        surveyId: surveyRef.id,
        options: const ['A', 'B'],
      );
      expect(results['A'], 2);
      expect(results['B'], 1);
    });
  });
}
