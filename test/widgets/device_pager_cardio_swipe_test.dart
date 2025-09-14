import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/device_provider.dart';
import 'package:tapem/features/device/domain/models/device.dart';
import 'package:tapem/features/device/domain/models/device_session_snapshot.dart';
import 'package:tapem/features/device/domain/repositories/device_repository.dart';
import 'package:tapem/features/device/presentation/widgets/cardio_runner.dart';
import 'package:tapem/features/device/presentation/widgets/device_pager.dart';
import 'package:tapem/features/device/presentation/widgets/read_only_snapshot_page.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/services/membership_service.dart';
import 'package:tapem/features/device/domain/usecases/get_devices_for_gym.dart';

class FakeMembershipService extends MembershipService {
  @override
  Future<void> ensureMembership(String gymId, String userId) async {}
}

class FakeDeviceRepository implements DeviceRepository {
  FakeDeviceRepository(this.devices);
  final List<Device> devices;
  @override
  DocumentSnapshot? get lastSnapshotCursor => null;
  @override
  Future<void> createDevice(String gymId, Device device) async {}
  @override
  Future<Device?> getDeviceByNfcCode(String gymId, String nfcCode) async => null;
  @override
  Future<List<Device>> getDevicesForGym(String gymId) async => devices;
  @override
  Future<DeviceSessionSnapshot?> getSnapshotBySessionId({required String gymId, required String deviceId, required String sessionId}) async => null;
  @override
  Future<void> updateMuscleGroups(String gymId, String deviceId, List<String> p, List<String> s) async {}
  @override
  Future<void> setMuscleGroups(String gymId, String deviceId, List<String> p, List<String> s) async {}
  @override
  Future<void> writeSessionSnapshot(String gymId, DeviceSessionSnapshot snapshot) async {}
  @override
  Future<List<DeviceSessionSnapshot>> fetchSessionSnapshotsPaginated({required String gymId, required String deviceId, required String userId, required int limit, String? exerciseId, DocumentSnapshot? startAfter}) async => [];
  @override
  Future<void> deleteDevice(String gymId, String deviceId) async {}
  @override
  Future<bool> hasSessionForDate({required String gymId, required String deviceId, required String userId, required DateTime date}) async => false;
}

void main() {
  testWidgets('right swipe opens snapshot', (tester) async {
    final firestore = FakeFirebaseFirestore();
    final device = Device(uid: 'c1', id: 1, name: 'Cardio', isCardio: true);
    await firestore
        .collection('gyms')
        .doc('g1')
        .collection('devices')
        .doc('c1')
        .collection('sessions')
        .doc('s1')
        .set({
      'sessionId': 's1',
      'deviceId': 'c1',
      'userId': 'u1',
      'createdAt': Timestamp.fromDate(DateTime.now()),
      'isCardio': true,
      'mode': 'timed',
      'durationSec': 10,
    });

    final provider = DeviceProvider(
      firestore: firestore,
      membership: FakeMembershipService(),
      getDevicesForGym: GetDevicesForGym(FakeDeviceRepository([device])),
      log: (_, [__]) {},
    );
    await provider.loadDevice(
      gymId: 'g1',
      deviceId: 'c1',
      exerciseId: 'ex1',
      userId: 'u1',
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ChangeNotifierProvider<DeviceProvider>.value(
          value: provider,
          child: DevicePager(
            editablePage: CardioRunner(onCancel: () {}, onSave: (_) {}),
            provider: provider,
            gymId: 'g1',
            deviceId: 'c1',
            userId: 'u1',
          ),
        ),
      ),
    );

    expect(find.byType(ReadOnlySnapshotPage), findsNothing);
    final size = tester.getSize(find.byType(DevicePager));
    await tester.dragFrom(Offset(0, size.height / 2), const Offset(300, 0));
    await tester.pumpAndSettle();
    expect(find.byType(ReadOnlySnapshotPage), findsOneWidget);
  });
}
