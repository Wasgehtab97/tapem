import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

FakeFirebaseFirestore makeFirestore() => FakeFirebaseFirestore();

Future<DocumentReference<Map<String, dynamic>>> seedSurvey(
  FakeFirebaseFirestore firestore, {
  required String gymId,
  String title = 'T',
  List<String> options = const ['A', 'B'],
  String status = 'open',
}) {
  return firestore
      .collection('gyms')
      .doc(gymId)
      .collection('surveys')
      .add({
        'title': title,
        'options': options,
        'status': status,
        'createdAt': Timestamp.now(),
      });
}

Future<void> seedSurveyAnswer(
  FakeFirebaseFirestore firestore, {
  required String gymId,
  required String surveyId,
  String userId = 'u1',
  String option = 'A',
}) {
  return firestore
      .collection('gyms')
      .doc(gymId)
      .collection('surveys')
      .doc(surveyId)
      .collection('answers')
      .add({
        'surveyId': surveyId,
        'userId': userId,
        'selectedOption': option,
        'timestamp': Timestamp.now(),
      });
}

Future<DocumentReference<Map<String, dynamic>>> seedFeedback(
  FakeFirebaseFirestore firestore, {
  required String gymId,
  String deviceId = 'd1',
  String userId = 'u1',
  String text = 'hi',
  bool isDone = false,
}) {
  return firestore
      .collection('gyms')
      .doc(gymId)
      .collection('feedback')
      .add({
        'deviceId': deviceId,
        'userId': userId,
        'text': text,
        'createdAt': Timestamp.now(),
        'isDone': isDone,
      });
}
