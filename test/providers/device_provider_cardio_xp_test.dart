import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/device_provider.dart';
import 'package:tapem/core/providers/xp_provider.dart';
import 'package:tapem/core/providers/challenge_provider.dart';
import 'package:tapem/features/device/domain/models/device.dart';
import 'package:tapem/features/device/domain/repositories/device_repository.dart';
import 'package:tapem/features/device/domain/usecases/get_devices_for_gym.dart';
import 'package:tapem/features/device/domain/models/device_session_snapshot.dart';
import 'package:tapem/features/xp/domain/xp_repository.dart';
import 'package:tapem/features/xp/domain/device_xp_result.dart';
import 'package:tapem/features/challenges/domain/repositories/challenge_repository.dart';
import 'package:tapem/features/challenges/domain/models/challenge.dart';
import 'package:tapem/features/challenges/domain/models/badge.dart';
import 'package:tapem/features/challenges/domain/models/completed_challenge.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tapem/services/membership_service.dart';

class FakeDeviceRepository implements DeviceRepository {
  FakeDeviceRepository(this.devices);
  final List<Device> devices;
  @override
  Future<List<Device>> getDevicesForGym(String gymId) async => devices;
  @override
  Future<void> writeSessionSnapshot(String gymId, DeviceSessionSnapshot snapshot) async {}
  @override
  DocumentSnapshot? get lastSnapshotCursor => null;
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeXpRepository implements XpRepository {
  int calls = 0;
  @override
  Future<DeviceXpResult> addSessionXp({
    required String gymId,
    required String userId,
    required String deviceId,
    required String sessionId,
    required bool showInLeaderboard,
    required bool isMulti,
    String? exerciseId,
    required String traceId,
  }) async {
    calls++;
    return DeviceXpResult.okAdded;
  }

  @override
  Stream<int> watchDayXp({required String userId, required DateTime date}) => const Stream.empty();
  @override
  Stream<Map<String, int>> watchMuscleXp({required String gymId, required String userId}) => const Stream.empty();
  @override
  Stream<Map<String, int>> watchTrainingDaysXp(String userId) => const Stream.empty();
  @override
  Stream<int> watchDeviceXp({required String gymId, required String deviceId, required String userId}) => const Stream.empty();
  @override
  Stream<int> watchStatsDailyXp({required String gymId, required String userId}) => const Stream.empty();
}

class FakeChallengeRepository implements ChallengeRepository {
  @override
  Future<void> checkChallenges(String gymId, String userId, String deviceId) async {}
  @override
  Stream<List<Challenge>> watchActiveChallenges(String gymId) => const Stream.empty();
  @override
  Stream<List<Badge>> watchBadges(String userId) => const Stream.empty();
  @override
  Stream<List<CompletedChallenge>> watchCompletedChallenges(String gymId, String userId) => const Stream.empty();
}

class FakeMembershipService implements MembershipService {
  @override
  Future<void> ensureMembership(String gymId, String uid) async {}
}

void main() {
  testWidgets('saveCardioTimedSession awards XP', (tester) async {
    final firestore = FakeFirebaseFirestore();
    final device = Device(uid: 'c1', id: 1, name: 'Cardio', isCardio: true);
    final provider = DeviceProvider(
      getDevicesForGym: GetDevicesForGym(FakeDeviceRepository([device])),
      firestore: firestore,
      log: (_, [__]) {},
      membership: FakeMembershipService(),
    );
    await provider.loadDevice(
      gymId: 'g1',
      deviceId: 'c1',
      exerciseId: 'ex1',
      userId: 'u1',
    );
    final xpRepo = FakeXpRepository();
    final xpProvider = XpProvider(repo: xpRepo);
    final challengeProvider = ChallengeProvider(repo: FakeChallengeRepository());
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<XpProvider>.value(value: xpProvider),
          ChangeNotifierProvider<ChallengeProvider>.value(value: challengeProvider),
          ChangeNotifierProvider<DeviceProvider>.value(value: provider),
        ],
        child: const MaterialApp(home: SizedBox()),
      ),
    );
    final ctx = tester.element(find.byType(SizedBox));
    final ok = await provider.saveCardioTimedSession(
      context: ctx,
      gymId: 'g1',
      userId: 'u1',
      durationSec: 30,
      showInLeaderboard: false,
    );
    expect(ok, isTrue);
    expect(xpRepo.calls, 1);
  });
}
