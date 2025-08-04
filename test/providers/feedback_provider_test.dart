import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:tapem/features/feedback/feedback_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setupFirebase();
  });

  group('FeedbackProvider', () {
    test('submitFeedback creates document', () async {
      final firestore = FakeFirebaseFirestore();
      final provider = FeedbackProvider(
        firestore: firestore,
        log: (_, [__]) {},
      );
      await provider.submitFeedback(
        gymId: 'g1',
        deviceId: 'd1',
        userId: 'u1',
        text: 'hi',
      );
      final snap = await firestore
          .collection('gyms')
          .doc('g1')
          .collection('feedback')
          .get();
      expect(snap.docs.length, 1);
    });

    test('loadFeedback reads entries', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore
          .collection('gyms')
          .doc('g1')
          .collection('feedback')
          .add({
            'deviceId': 'd1',
            'userId': 'u1',
            'text': 'hi',
            'createdAt': Timestamp.now(),
            'isDone': false,
          });
      final provider = FeedbackProvider(
        firestore: firestore,
        log: (_, [__]) {},
      );
      await provider.loadFeedback('g1');
      expect(provider.entries.length, 1);
    });

    test('markDone updates entry', () async {
      final firestore = FakeFirebaseFirestore();
      final doc = await firestore
          .collection('gyms')
          .doc('g1')
          .collection('feedback')
          .add({
            'deviceId': 'd1',
            'userId': 'u1',
            'text': 'hi',
            'createdAt': Timestamp.now(),
            'isDone': false,
          });
      final provider = FeedbackProvider(
        firestore: firestore,
        log: (_, [__]) {},
      );
      await provider.loadFeedback('g1');
      await provider.markDone(gymId: 'g1', entryId: doc.id);
      final updated = await doc.get();
      expect(updated.data()?['isDone'], true);
      expect(provider.doneEntries.length, 1);
    });
  });
}
