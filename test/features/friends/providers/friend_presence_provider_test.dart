import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/friends/providers/friend_presence_provider.dart';

void main() {
  Future<void> _writePresence(
    FakeFirebaseFirestore fs,
    String uid,
    bool workedOut,
  ) async {
    final now = DateTime.now();
    final key =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    await fs
        .collection('dailyPresence')
        .doc(key)
        .collection('users')
        .doc(uid)
        .set({'workedOut': workedOut});
  }

  test('reads aggregated presence flag', () async {
    final fs = FakeFirebaseFirestore();
    await _writePresence(fs, 'u1', true);
    final prov = FriendPresenceProvider(firestore: fs);
    prov.updateUids(['u1']);
    await Future.delayed(const Duration(milliseconds: 50));
    expect(prov.stateFor('u1'), PresenceState.workedOutToday);
  });

  test('refresh picks up new presence state', () async {
    final fs = FakeFirebaseFirestore();
    await _writePresence(fs, 'u2', false);
    final prov = FriendPresenceProvider(firestore: fs);
    prov.updateUids(['u2']);
    await Future.delayed(const Duration(milliseconds: 50));
    expect(prov.stateFor('u2'), PresenceState.notWorkedOutToday);

    await _writePresence(fs, 'u2', true);
    await prov.refresh();
    expect(prov.stateFor('u2'), PresenceState.workedOutToday);
  });
}
