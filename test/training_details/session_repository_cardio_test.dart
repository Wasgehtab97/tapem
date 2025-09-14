import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/training_details/data/repositories/session_repository_impl.dart';
import 'package:tapem/features/training_details/data/sources/firestore_session_source.dart';
import 'package:tapem/features/training_details/data/session_meta_source.dart';

void main() {
  test('loadSessions returns strength and cardio', () async {
    final ff = FakeFirebaseFirestore();
    final logs = ff.collection('gyms').doc('g1').collection('devices');
    // strength log
    await logs.doc('d1').collection('logs').add({
      'sessionId': 's1',
      'deviceId': 'd1',
      'exerciseId': 'e1',
      'userId': 'u1',
      'timestamp': Timestamp.fromDate(DateTime(2024,1,1,12)),
      'setNumber': 1,
      'weight': 10,
      'reps': 5,
    });
    // cardio log
    await logs.doc('c1').collection('logs').add({
      'sessionId': 's2',
      'deviceId': 'c1',
      'exerciseId': 'e1',
      'userId': 'u1',
      'timestamp': Timestamp.fromDate(DateTime(2024,1,1,13)),
      'setNumber': 1,
      'isCardio': true,
      'mode': 'timed',
      'durationSec': 180,
    });
    final repo = SessionRepositoryImpl(
      FirestoreSessionSource(firestore: ff),
      SessionMetaSource(firestore: ff),
    );
    final sessions = await repo.getSessionsForDate(
      userId: 'u1',
      date: DateTime(2024,1,1),
    );
    expect(sessions.length, 2);
    final cardio = sessions.firstWhere((s) => s.isCardio);
    expect(cardio.durationSec, 180);
    final strength = sessions.firstWhere((s) => !s.isCardio);
    expect(strength.sets.first.weight, 10);
  });
}
