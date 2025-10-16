import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/training_details/data/sources/firestore_session_source.dart';

void main() {
  test('fetches full session history via paginated queries', () async {
    final firestore = FakeFirebaseFirestore();
    const gymId = 'g1';
    const deviceId = 'd1';
    const sessionId = 's1';
    const userId = 'u1';

    final logs = firestore
        .collection('gyms')
        .doc(gymId)
        .collection('devices')
        .doc(deviceId)
        .collection('logs');

    for (var i = 0; i < 120; i++) {
      await logs.doc('log_$i').set({
        'sessionId': sessionId,
        'userId': userId,
        'exerciseId': 'exercise',
        'timestamp': Timestamp.fromMillisecondsSinceEpoch(1704067200000 + i * 60000),
        'weight': 50,
        'reps': 10,
        'setNumber': i + 1,
        'note': '',
      });
    }

    final source = FirestoreSessionSource(firestore: firestore);
    final entries = await source.getSessionEntries(
      gymId: gymId,
      deviceId: deviceId,
      sessionId: sessionId,
      userId: userId,
    );

    expect(entries.length, equals(120));
    for (var i = 1; i < entries.length; i++) {
      expect(
        entries[i].timestamp.isAfter(entries[i - 1].timestamp) ||
            entries[i].timestamp.isAtSameMomentAs(entries[i - 1].timestamp),
        isTrue,
        reason: 'entries must be sorted by timestamp ascending',
      );
    }
  });
}
