import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/core/time/logic_day.dart';
import 'package:tapem/features/rank/domain/services/level_service.dart';
import 'package:tapem/features/xp/data/sources/firestore_xp_source.dart';
import 'package:tapem/features/xp/domain/device_xp_result.dart';

import '../../auth/helpers/fake_firestore.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FirestoreXpSource.addSessionXp', () {
    const gymId = 'gymA';
    const userId = 'userA';
    const deviceId = 'deviceA';
    const traceId = 'trace';
    const timeZone = 'UTC';
    final sessionDate = DateTime(2024, 1, 1, 12, 30);
    final dayKey = logicDayKey(DateTime(2024, 1, 1));

    late FakeFirebaseFirestore firestore;
    late FirestoreXpSource source;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      source = FirestoreXpSource(firestore: firestore);
    });

    Future<Map<String, dynamic>> _fetchStats() async {
      final snap = await firestore
          .collection('gyms')
          .doc(gymId)
          .collection('users')
          .doc(userId)
          .collection('rank')
          .doc('stats')
          .get();
      return snap.data() ?? <String, dynamic>{};
    }

    test('subsequent sessions on same day keep daily XP but award device and muscle XP', () async {
      final firstAward = await source.addSessionXp(
        gymId: gymId,
        userId: userId,
        deviceId: deviceId,
        sessionId: 'session-1',
        showInLeaderboard: true,
        isMulti: false,
        exerciseId: 'exercise-1',
        traceId: '$traceId-1',
        sessionDate: sessionDate,
        timeZone: timeZone,
        primaryMuscleGroupIds: const ['chest'],
        secondaryMuscleGroupIds: const [],
      );

      expect(firstAward.result, DeviceXpResult.okAdded);
      expect(firstAward.xpDelta, LevelService.xpPerSession);
      expect(firstAward.totalXp, LevelService.xpPerSession);
      expect(firstAward.dayXp, LevelService.xpPerSession);

      final secondAward = await source.addSessionXp(
        gymId: gymId,
        userId: userId,
        deviceId: deviceId,
        sessionId: 'session-2',
        showInLeaderboard: true,
        isMulti: false,
        exerciseId: 'exercise-1',
        traceId: '$traceId-2',
        sessionDate: sessionDate.add(const Duration(hours: 1)),
        timeZone: timeZone,
        primaryMuscleGroupIds: const ['chest'],
        secondaryMuscleGroupIds: const [],
      );

      expect(secondAward.result, DeviceXpResult.okAddedNoLeaderboard);
      expect(secondAward.xpDelta, 0);
      expect(secondAward.totalXp, LevelService.xpPerSession);
      expect(secondAward.dayXp, LevelService.xpPerSession);

      final duplicateAward = await source.addSessionXp(
        gymId: gymId,
        userId: userId,
        deviceId: deviceId,
        sessionId: 'session-2',
        showInLeaderboard: true,
        isMulti: false,
        exerciseId: 'exercise-1',
        traceId: '$traceId-dup',
        sessionDate: sessionDate.add(const Duration(hours: 2)),
        timeZone: timeZone,
        primaryMuscleGroupIds: const ['chest'],
        secondaryMuscleGroupIds: const [],
      );

      expect(duplicateAward.result, DeviceXpResult.idempotentHit);
      expect(duplicateAward.xpDelta, 0);

      final dayDoc = await firestore
          .collection('users')
          .doc(userId)
          .collection('trainingDayXP')
          .doc(dayKey)
          .get();
      expect(dayDoc.exists, isTrue);
      expect(dayDoc.data()!['xp'], LevelService.xpPerSession);

      final stats = await _fetchStats();
      expect(stats['dailyXP'], LevelService.xpPerSession);
      expect(stats['chestXP'], LevelService.xpPerSession * 2);

      final leaderboardSnap = await firestore
          .collection('gyms')
          .doc(gymId)
          .collection('devices')
          .doc(deviceId)
          .collection('leaderboard')
          .doc(userId)
          .get();
      expect(leaderboardSnap.exists, isTrue);
      expect(leaderboardSnap.data()!['xp'], LevelService.xpPerSession * 2);
    });
  });
}
