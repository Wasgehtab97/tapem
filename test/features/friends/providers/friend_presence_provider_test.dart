import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tapem/features/friends/providers/friend_presence_provider.dart';

void main() {
  test('fallback query detects workout', () async {
    final fs = FakeFirebaseFirestore();
    await fs.collection('logs').add({
      'userId': 'u1',
      'timestamp': Timestamp.fromDate(DateTime.now()),
    });
    final prov = FriendPresenceProvider(firestore: fs);
    prov.updateUids(['u1']);
    await Future.delayed(const Duration(milliseconds: 50));
    expect(prov.stateFor('u1'), PresenceState.workedOutToday);
  });

  test('fallback query detects no workout', () async {
    final fs = FakeFirebaseFirestore();
    final prov = FriendPresenceProvider(firestore: fs);
    prov.updateUids(['u2']);
    await Future.delayed(const Duration(milliseconds: 50));
    expect(prov.stateFor('u2'), PresenceState.notWorkedOutToday);
  });
}
