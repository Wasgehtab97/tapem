import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/rank/data/sources/firestore_rank_source.dart';
import 'package:tapem/features/xp/domain/device_xp_result.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FirestoreRankSource.addXp', () {
    test('credits XP for every session even if exercise repeats on the same day', () async {
      final firestore = FakeFirebaseFirestore();
      final source = FirestoreRankSource(firestore: firestore);

      final result1 = await source.addXp(
        gymId: 'g1',
        userId: 'u1',
        deviceId: 'd1',
        sessionId: 's1',
        showInLeaderboard: true,
        isMulti: true,
        exerciseId: 'ex1',
        traceId: 't1',
      );
      expect(result1, DeviceXpResult.okAdded);

      final result2 = await source.addXp(
        gymId: 'g1',
        userId: 'u1',
        deviceId: 'd1',
        sessionId: 's2',
        showInLeaderboard: true,
        isMulti: true,
        exerciseId: 'ex1',
        traceId: 't2',
      );
      expect(result2, DeviceXpResult.okAdded);

      final leaderboardDoc = await firestore
          .collection('gyms')
          .doc('g1')
          .collection('devices')
          .doc('d1')
          .collection('leaderboard')
          .doc('u1')
          .get();

      expect(leaderboardDoc.data()?['xp'], 100);

      final sessionsSnap = await leaderboardDoc.reference.collection('sessions').get();
      expect(sessionsSnap.docs.length, 2);

      final result3 = await source.addXp(
        gymId: 'g1',
        userId: 'u1',
        deviceId: 'd1',
        sessionId: 's1',
        showInLeaderboard: true,
        isMulti: true,
        exerciseId: 'ex1',
        traceId: 't3',
      );
      expect(result3, DeviceXpResult.idempotentHit);

      final leaderboardDocAfter = await leaderboardDoc.reference.get();
      expect(leaderboardDocAfter.data()?['xp'], 100);
    });
  });
}
