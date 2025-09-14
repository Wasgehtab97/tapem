import 'package:flutter/material.dart' hide Badge;
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
  Future<void> createDevice(String gymId, Device device) => throw UnimplementedError();
  @override
  Future<Device?> getDeviceByNfcCode(String gymId, String nfcCode) => throw UnimplementedError();
  @override
  Future<void> deleteDevice(String gymId, String deviceId) => throw UnimplementedError();
  @override
  Future<void> updateMuscleGroups(String gymId, String deviceId, List<String> primaryGroups, List<String> secondaryGroups) => throw UnimplementedError();
  @override
  Future<void> setMuscleGroups(String gymId, String deviceId, List<String> primaryGroups, List<String> secondaryGroups) => throw UnimplementedError();

  @override
  Future<void> writeSessionSnapshot(String gymId, DeviceSessionSnapshot snapshot) async {}

  @override
  Future<List<DeviceSessionSnapshot>> fetchSessionSnapshotsPaginated({
    required String gymId,
    required String deviceId,
    required String userId,
    required int limit,
    String? exerciseId,
    DocumentSnapshot? startAfter,
  }) async => <DeviceSessionSnapshot>[];

  @override
  Future<DeviceSessionSnapshot?> getSnapshotBySessionId({
    required String gymId,
    required String deviceId,
    required String sessionId,
  }) async => null;

  @override
  DocumentSnapshot? get lastSnapshotCursor => null;
}

class FakeMembershipService implements MembershipService {
  @override
  Future<void> ensureMembership(String gymId, String uid) async {}
}

class _ExerciseSnapRepo implements DeviceRepository {
  final List<Device> devices;
  final Map<String, List<DeviceSessionSnapshot>> snaps;
  _ExerciseSnapRepo(this.devices, this.snaps);

  @override
  Future<List<Device>> getDevicesForGym(String gymId) async => devices;

  @override
  Future<List<DeviceSessionSnapshot>> fetchSessionSnapshotsPaginated({
    required String gymId,
    required String deviceId,
    required String userId,
    required int limit,
    String? exerciseId,
    DocumentSnapshot? startAfter,
  }) async => snaps[exerciseId] ?? [];

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
  int calls = 0;
  @override
  Future<void> checkChallenges(String gymId, String userId, String deviceId) async {
    calls++;
  }

  @override
  Stream<List<Challenge>> watchActiveChallenges(String gymId) => const Stream.empty();
  @override
  Stream<List<Badge>> watchBadges(String userId) =>
      const Stream<List<Badge>>.empty();
  @override
  Stream<List<CompletedChallenge>> watchCompletedChallenges(String gymId, String userId) => const Stream.empty();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DeviceProvider', () {
    test('loadDevice sets device and last session', () async {
      final firestore = FakeFirebaseFirestore();
      final logsCol = firestore
          .collection('gyms')
          .doc('g1')
          .collection('devices')
          .doc('d1')
          .collection('logs');
      final ts1 = Timestamp.fromDate(DateTime(2024, 1, 1));
      final ts2 = Timestamp.fromDate(DateTime(2024, 1, 1, 1));
      await logsCol.add({
        'deviceId': 'd1',
        'userId': 'u1',
        'exerciseId': 'ex1',
        'sessionId': 's1',
        'timestamp': ts1,
        'weight': 50.0,
        'reps': 10,
        'note': 'n',
        'dropWeightKg': 40.0,
        'dropReps': 5,
      });
      await logsCol.add({
        'deviceId': 'd1',
        'userId': 'u1',
        'exerciseId': 'ex1',
        'sessionId': 's1',
        'timestamp': ts2,
        'weight': 60.0,
        'reps': 8,
        'note': 'n',
      });
      await firestore
          .collection('gyms')
          .doc('g1')
          .collection('devices')
          .doc('d1')
          .collection('leaderboard')
          .doc('u1')
          .set({'xp': 10, 'level': 2});

      final device = Device(
        uid: 'd1',
        id: 1,
        name: 'Device',
        primaryMuscleGroups: const ['m1'],
      );
      final provider = DeviceProvider(
        getDevicesForGym: GetDevicesForGym(FakeDeviceRepository([device])),
        firestore: firestore,
        log: (_, [__]) {},
        membership: FakeMembershipService(),
      );

      await provider.loadDevice(
        gymId: 'g1',
        deviceId: 'd1',
        exerciseId: 'ex1',
        userId: 'u1',
      );

      expect(provider.device?.uid, 'd1');
      expect(provider.lastSessionSets.length, 2);
      expect(provider.lastSessionSets.first['dropWeight'], '40.0');
      expect(provider.lastSessionSets.first['dropReps'], '5');
    });

    testWidgets('saveWorkoutSession writes log and adds XP', (tester) async {
      final firestore = FakeFirebaseFirestore();
      final device = Device(
        uid: 'd1',
        id: 1,
        name: 'Device',
        primaryMuscleGroups: const ['m1'],
      );
      final xpRepo = FakeXpRepository();
      final chRepo = FakeChallengeRepository();
      final provider = DeviceProvider(
        getDevicesForGym: GetDevicesForGym(FakeDeviceRepository([device])),
        firestore: firestore,
        log: (_, [__]) {},
        membership: FakeMembershipService(),
      );
      await provider.loadDevice(
        gymId: 'g1',
        deviceId: 'd1',
        exerciseId: 'ex1',
        userId: 'u1',
      );
      provider.updateSet(0,
          weight: '70', reps: '6', dropWeight: '60', dropReps: '5');
      provider.toggleSetDone(0);
      provider.setNote('test');

      final xpProvider = XpProvider(repo: xpRepo);
      final challengeProvider = ChallengeProvider(repo: chRepo);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<XpProvider>.value(value: xpProvider),
            ChangeNotifierProvider<ChallengeProvider>.value(value: challengeProvider),
            ChangeNotifierProvider<DeviceProvider>.value(value: provider),
          ],
          child: const MaterialApp(home: Scaffold(body: SizedBox())),
        ),
      );

      final ctx = tester.element(find.byType(SizedBox));
      final ok = await provider.saveWorkoutSession(
        context: ctx,
        gymId: 'g1',
        userId: 'u1',
        showInLeaderboard: false,
      );
      expect(ok, isTrue);

      final logs = await firestore
          .collection('gyms')
          .doc('g1')
          .collection('devices')
          .doc('d1')
          .collection('logs')
          .get();
      expect(logs.docs.length, 1);
      expect(logs.docs.first.data()['dropWeightKg'], 60.0);
      expect(logs.docs.first.data()['dropReps'], 5);
      expect(xpRepo.calls, 1);
      expect(chRepo.calls, 1);
    });

    testWidgets('saveWorkoutSession cardio persists speed only', (tester) async {
      final firestore = FakeFirebaseFirestore();
      final device = Device(
        uid: 'c1',
        id: 1,
        name: 'Cardio',
        isCardio: true,
        primaryMuscleGroups: const ['m1'],
      );
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
      provider.updateSet(0, speed: '10');
      provider.toggleSetDone(0);

      await tester.pumpWidget(
        ChangeNotifierProvider<DeviceProvider>.value(
          value: provider,
          child: const MaterialApp(home: Scaffold(body: SizedBox())),
        ),
      );

      final ctx = tester.element(find.byType(SizedBox));
      final ok = await provider.saveWorkoutSession(
        context: ctx,
        gymId: 'g1',
        userId: 'u1',
        showInLeaderboard: false,
      );
      expect(ok, isTrue);

      final logs = await firestore
          .collection('gyms')
          .doc('g1')
          .collection('devices')
          .doc('c1')
          .collection('logs')
          .get();
      expect(logs.docs.first.data()['speedKmH'], 10);
      expect(logs.docs.first.data().containsKey('durationSec'), false);
    });

    testWidgets('saveWorkoutSession without completed sets aborts', (tester) async {
      final firestore = FakeFirebaseFirestore();
      final device = Device(
        uid: 'd1',
        id: 1,
        name: 'Device',
        primaryMuscleGroups: const ['m1'],
      );
      final provider = DeviceProvider(
        getDevicesForGym: GetDevicesForGym(FakeDeviceRepository([device])),
        firestore: firestore,
        log: (_, [__]) {},
        membership: FakeMembershipService(),
      );
      await provider.loadDevice(
        gymId: 'g1',
        deviceId: 'd1',
        exerciseId: 'ex1',
        userId: 'u1',
      );
      provider.updateSet(0, weight: '70', reps: '6');

      await tester.pumpWidget(
        ChangeNotifierProvider<DeviceProvider>.value(
          value: provider,
          child: const MaterialApp(home: Scaffold(body: SizedBox())),
        ),
      );

      final ctx = tester.element(find.byType(SizedBox));
      final ok = await provider.saveWorkoutSession(
        context: ctx,
        gymId: 'g1',
        userId: 'u1',
        showInLeaderboard: false,
      );
      expect(ok, isFalse);

      final logs = await firestore
          .collection('gyms')
          .doc('g1')
          .collection('devices')
          .doc('d1')
          .collection('logs')
          .get();
      expect(logs.docs.length, 0);
      expect(provider.error, isNotNull);
    });

    test('toggleSetDone validates inputs', () {
      final provider = DeviceProvider(
        firestore: FakeFirebaseFirestore(),
        getDevicesForGym: GetDevicesForGym(FakeDeviceRepository([])),
        log: (_, [__]) {},
        membership: FakeMembershipService(),
      );
      provider.addSet();
      provider.updateSet(0, weight: '10');
      provider.toggleSetDone(0);
      expect(provider.completedCount, 0);
      provider.updateSet(0, reps: '5');
      provider.toggleSetDone(0);
    expect(provider.completedCount, 1);
  });

  group('cardio validation', () {
    test('set complete with speed only', () async {
      final firestore = FakeFirebaseFirestore();
      final device = Device(
        uid: 'c1',
        id: 1,
        name: 'Cardio',
        isCardio: true,
        primaryMuscleGroups: const ['m1'],
      );
      final provider = DeviceProvider(
        firestore: firestore,
        getDevicesForGym: GetDevicesForGym(FakeDeviceRepository([device])),
        log: (_, [__]) {},
        membership: FakeMembershipService(),
      );
      await provider.loadDevice(
        gymId: 'g1',
        deviceId: 'c1',
        exerciseId: 'ex1',
        userId: 'u1',
      );
      provider.updateSet(0, speed: '10');
      final ok = provider.toggleSetDone(0);
      expect(ok, true);
    });

    test('invalid speed blocks completion', () async {
      final firestore = FakeFirebaseFirestore();
      final device = Device(
        uid: 'c1',
        id: 1,
        name: 'Cardio',
        isCardio: true,
        primaryMuscleGroups: const ['m1'],
      );
      final provider = DeviceProvider(
        firestore: firestore,
        getDevicesForGym: GetDevicesForGym(FakeDeviceRepository([device])),
        log: (_, [__]) {},
        membership: FakeMembershipService(),
      );
      await provider.loadDevice(
        gymId: 'g1',
        deviceId: 'c1',
        exerciseId: 'ex1',
        userId: 'u1',
      );
      provider.updateSet(0, speed: '0');
      final ok = provider.toggleSetDone(0);
      expect(ok, false);
    });

    test('invalid duration blocks completion', () async {
      final firestore = FakeFirebaseFirestore();
      final device = Device(
        uid: 'c1',
        id: 1,
        name: 'Cardio',
        isCardio: true,
        primaryMuscleGroups: const ['m1'],
      );
      final provider = DeviceProvider(
        firestore: firestore,
        getDevicesForGym: GetDevicesForGym(FakeDeviceRepository([device])),
        log: (_, [__]) {},
        membership: FakeMembershipService(),
      );
      await provider.loadDevice(
        gymId: 'g1',
        deviceId: 'c1',
        exerciseId: 'ex1',
        userId: 'u1',
      );
      provider.updateSet(0, speed: '10', duration: '03:00:01');
      final ok = provider.toggleSetDone(0);
      expect(ok, false);
    });

    test('accepts decimal and comma speeds', () async {
      final firestore = FakeFirebaseFirestore();
      final device = Device(
        uid: 'c1',
        id: 1,
        name: 'Cardio',
        isCardio: true,
        primaryMuscleGroups: const ['m1'],
      );
      final provider = DeviceProvider(
        firestore: firestore,
        getDevicesForGym: GetDevicesForGym(FakeDeviceRepository([device])),
        log: (_, [__]) {},
        membership: FakeMembershipService(),
      );
      await provider.loadDevice(
        gymId: 'g1',
        deviceId: 'c1',
        exerciseId: 'ex1',
        userId: 'u1',
      );
      provider.updateSet(0, speed: '10,5');
      expect(provider.toggleSetDone(0), true);
      provider.updateSet(0, done: false, speed: '005');
      expect(provider.toggleSetDone(0), true);
    });

    test('speed over max invalid', () async {
      final firestore = FakeFirebaseFirestore();
      final device = Device(
        uid: 'c1',
        id: 1,
        name: 'Cardio',
        isCardio: true,
        primaryMuscleGroups: const ['m1'],
      );
      final provider = DeviceProvider(
        firestore: firestore,
        getDevicesForGym: GetDevicesForGym(FakeDeviceRepository([device])),
        log: (_, [__]) {},
        membership: FakeMembershipService(),
      );
      await provider.loadDevice(
        gymId: 'g1',
        deviceId: 'c1',
        exerciseId: 'ex1',
        userId: 'u1',
      );
      provider.updateSet(0, speed: '50');
      expect(provider.toggleSetDone(0), false);
    });

    test('non numeric speed invalid', () async {
      final firestore = FakeFirebaseFirestore();
      final device = Device(
        uid: 'c1',
        id: 1,
        name: 'Cardio',
        isCardio: true,
        primaryMuscleGroups: const ['m1'],
      );
      final provider = DeviceProvider(
        firestore: firestore,
        getDevicesForGym: GetDevicesForGym(FakeDeviceRepository([device])),
        log: (_, [__]) {},
        membership: FakeMembershipService(),
      );
      await provider.loadDevice(
        gymId: 'g1',
        deviceId: 'c1',
        exerciseId: 'ex1',
        userId: 'u1',
      );
      provider.updateSet(0, speed: 'abc');
      expect(provider.toggleSetDone(0), false);
    });
  });

    test('loadDevice filters snapshots by exercise for multi device', () async {
      final repo = _ExerciseSnapRepo(
        [
          Device(
            uid: 'd1',
            id: 1,
            name: 'D',
            isMulti: true,
            primaryMuscleGroups: const ['m1'],
          ),
        ],
        {
          'ex1': [
            DeviceSessionSnapshot(
              sessionId: 's1',
              deviceId: 'd1',
              exerciseId: 'ex1',
              createdAt: DateTime(2024, 1, 1),
              userId: 'u1',
              sets: const [SetEntry(kg: 10, reps: 5)],
            ),
          ],
          'ex2': [
            DeviceSessionSnapshot(
              sessionId: 's2',
              deviceId: 'd1',
              exerciseId: 'ex2',
              createdAt: DateTime(2024, 1, 2),
              userId: 'u1',
              sets: const [SetEntry(kg: 20, reps: 5)],
            ),
          ],
        },
      );

      final provider = DeviceProvider(
        getDevicesForGym: GetDevicesForGym(repo),
        deviceRepository: repo,
        firestore: FakeFirebaseFirestore(),
        log: (_, [__]) {},
        membership: FakeMembershipService(),
      );

      await provider.loadDevice(
        gymId: 'g1',
        deviceId: 'd1',
        exerciseId: 'ex1',
        userId: 'u1',
      );
      expect(provider.sessionSnapshots.length, 1);
      expect(provider.sessionSnapshots.first.exerciseId, 'ex1');

      await provider.loadDevice(
        gymId: 'g1',
        deviceId: 'd1',
        exerciseId: 'ex2',
        userId: 'u1',
      );
      expect(provider.sessionSnapshots.length, 1);
      expect(provider.sessionSnapshots.first.exerciseId, 'ex2');
    });

    testWidgets('second save in same day is blocked', (tester) async {
      final firestore = FakeFirebaseFirestore();
      final device = Device(
        uid: 'd1',
        id: 1,
        name: 'Device',
        primaryMuscleGroups: const ['m1'],
      );
      final xpRepo = FakeXpRepository();
      final chRepo = FakeChallengeRepository();
      final provider = DeviceProvider(
        getDevicesForGym: GetDevicesForGym(FakeDeviceRepository([device])),
        firestore: firestore,
        log: (_, [__]) {},
        membership: FakeMembershipService(),
      );
      await provider.loadDevice(
        gymId: 'g1',
        deviceId: 'd1',
        exerciseId: 'ex1',
        userId: 'u1',
      );
      provider.updateSet(0, weight: '70', reps: '6');
      provider.toggleSetDone(0);

      final xpProvider = XpProvider(repo: xpRepo);
      final challengeProvider = ChallengeProvider(repo: chRepo);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<XpProvider>.value(value: xpProvider),
            ChangeNotifierProvider<ChallengeProvider>.value(value: challengeProvider),
            ChangeNotifierProvider<DeviceProvider>.value(value: provider),
          ],
          child: const MaterialApp(home: Scaffold(body: SizedBox())),
        ),
      );

      final ctx = tester.element(find.byType(SizedBox));
      var ok = await provider.saveWorkoutSession(
        context: ctx,
        gymId: 'g1',
        userId: 'u1',
        showInLeaderboard: false,
      );
      expect(ok, isTrue);

      provider.updateSet(0, weight: '70', reps: '6');
      provider.toggleSetDone(0);
      ok = await provider.saveWorkoutSession(
        context: ctx,
        gymId: 'g1',
        userId: 'u1',
        showInLeaderboard: false,
      );
      expect(ok, isFalse);

      expect(provider.error, 'Heute bereits gespeichert.');
    });

    test('patchDeviceGroups updates device and notifies', () async {
      final provider = DeviceProvider(
        firestore: FakeFirebaseFirestore(),
        getDevicesForGym: GetDevicesForGym(
          FakeDeviceRepository([
            Device(uid: 'd1', id: 1, name: 'D'),
          ]),
        ),
        log: (_, [__]) {},
        membership: FakeMembershipService(),
      );
      await provider.loadDevices('g1', 'u1');
      var calls = 0;
      provider.addListener(() => calls++);
      provider.patchDeviceGroups('d1', ['p'], ['s']);
      expect(provider.devices.first.primaryMuscleGroups, ['p']);
      expect(provider.devices.first.secondaryMuscleGroups, ['s']);
      expect(calls, 1);
    });

    test('cardio set validation', () async {
      final firestore = FakeFirebaseFirestore();
      final device = Device(
        uid: 'c1',
        id: 1,
        name: 'Cardio',
        isCardio: true,
        primaryMuscleGroups: const ['m1'],
      );
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
      provider.updateSet(0, speed: '10', duration: '00:10:00');
      expect(provider.toggleSetDone(0), true);
      provider.updateSet(0, speed: '0', duration: '00:00:00');
      expect(provider.toggleSetDone(0), false);
    });

  });

  testWidgets('cardio save omits empty duration', (tester) async {
    final firestore = FakeFirebaseFirestore();
    final device = Device(
      uid: 'c1',
      id: 1,
      name: 'Cardio',
      isCardio: true,
      primaryMuscleGroups: const ['m1'],
    );
    final xpRepo = FakeXpRepository();
    final chRepo = FakeChallengeRepository();
    final provider = DeviceProvider(
      firestore: firestore,
      getDevicesForGym: GetDevicesForGym(FakeDeviceRepository([device])),
      log: (_, [__]) {},
      membership: FakeMembershipService(),
    );
    await provider.loadDevice(
      gymId: 'g1',
      deviceId: 'c1',
      exerciseId: 'ex1',
      userId: 'u1',
    );
    provider.updateSet(0, speed: '10');
    provider.toggleSetDone(0);

    final xpProvider = XpProvider(repo: xpRepo);
    final challengeProvider = ChallengeProvider(repo: chRepo);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<XpProvider>.value(value: xpProvider),
          ChangeNotifierProvider<ChallengeProvider>.value(
              value: challengeProvider),
          ChangeNotifierProvider<DeviceProvider>.value(value: provider),
        ],
        child: const MaterialApp(home: Scaffold(body: SizedBox())),
      ),
    );
    final ctx = tester.element(find.byType(SizedBox));
    var ok = await provider.saveWorkoutSession(
      context: ctx,
      gymId: 'g1',
      userId: 'u1',
      showInLeaderboard: false,
    );
    expect(ok, true);

    final logs = await firestore
        .collection('gyms')
        .doc('g1')
        .collection('devices')
        .doc('c1')
        .collection('logs')
        .orderBy('setNumber')
        .get();
    expect(logs.docs.first.data().containsKey('durationSec'), false);

    final provider2 = DeviceProvider(
      firestore: firestore,
      getDevicesForGym: GetDevicesForGym(FakeDeviceRepository([device])),
      log: (_, [__]) {},
      membership: FakeMembershipService(),
    );
    await provider2.loadDevice(
      gymId: 'g1',
      deviceId: 'c1',
      exerciseId: 'ex1',
      userId: 'u1',
    );
    provider2.updateSet(0, speed: '10', duration: '00:00:05');
    provider2.toggleSetDone(0);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<XpProvider>.value(value: xpProvider),
          ChangeNotifierProvider<ChallengeProvider>.value(
              value: challengeProvider),
          ChangeNotifierProvider<DeviceProvider>.value(value: provider2),
        ],
        child: const MaterialApp(home: Scaffold(body: SizedBox())),
      ),
    );
    final ctx2 = tester.element(find.byType(SizedBox));
    ok = await provider2.saveWorkoutSession(
      context: ctx2,
      gymId: 'g1',
      userId: 'u1',
      showInLeaderboard: false,
    );
    expect(ok, true);

    final logs2 = await firestore
        .collection('gyms')
        .doc('g1')
        .collection('devices')
        .doc('c1')
        .collection('logs')
        .orderBy('setNumber')
        .get();
    expect(logs2.docs[1].data()['durationSec'], 5);
  });
}

