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
import 'package:tapem/features/xp/domain/xp_repository.dart';
import 'package:tapem/features/challenges/domain/repositories/challenge_repository.dart';
import 'package:tapem/features/challenges/domain/models/challenge.dart';
import 'package:tapem/features/challenges/domain/models/badge.dart';
import 'package:tapem/features/challenges/domain/models/completed_challenge.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
}

class FakeXpRepository implements XpRepository {
  int calls = 0;
  @override
  Future<void> addSessionXp({
    required String gymId,
    required String userId,
    required String deviceId,
    required String sessionId,
    required bool showInLeaderboard,
    required bool isMulti,
    required List<String> primaryMuscleGroupIds,
  }) async {
    calls++;
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
      );

      await provider.loadDevice(
        gymId: 'g1',
        deviceId: 'd1',
        exerciseId: 'ex1',
        userId: 'u1',
      );

      expect(provider.device?.uid, 'd1');
      expect(provider.lastSessionSets.length, 2);
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
      );
      await provider.loadDevice(
        gymId: 'g1',
        deviceId: 'd1',
        exerciseId: 'ex1',
        userId: 'u1',
      );
      provider.updateSet(0, weight: '70', reps: '6');
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
      await provider.saveWorkoutSession(
        context: ctx,
        gymId: 'g1',
        userId: 'u1',
        showInLeaderboard: false,
      );

      final logs = await firestore
          .collection('gyms')
          .doc('g1')
          .collection('devices')
          .doc('d1')
          .collection('logs')
          .get();
      expect(logs.docs.length, 1);
      expect(xpRepo.calls, 1);
      expect(chRepo.calls, 1);
    });
  });
}

