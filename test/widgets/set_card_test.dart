import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/device_provider.dart';
import 'package:tapem/features/device/presentation/widgets/set_card.dart';
import 'package:tapem/features/device/domain/usecases/get_devices_for_gym.dart';
import 'package:tapem/features/device/domain/repositories/device_repository.dart';
import 'package:tapem/features/device/domain/models/device.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/ui/numeric_keypad/overlay_numeric_keypad.dart';
import 'package:tapem/features/device/domain/models/device_session_snapshot.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tapem/services/membership_service.dart';

class _FakeRepo implements DeviceRepository {
  final List<Device> devices;
  _FakeRepo([this.devices = const []]);
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

void main() {
  testWidgets('SetCard toggle locks fields', (tester) async {
    final provider = DeviceProvider(
      firestore: FakeFirebaseFirestore(),
      getDevicesForGym: GetDevicesForGym(_FakeRepo()),
      log: (_, [__]) {},
      membership: FakeMembershipService(),
    );
    provider.addSet();

    final keypadController = OverlayNumericKeypadController();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<DeviceProvider>.value(value: provider),
          Provider<OverlayNumericKeypadController>.value(
            value: keypadController,
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => OverlayNumericKeypadHost(
            controller: keypadController,
            outsideTapMode: OutsideTapMode.closeAfterTap,
            child: child!,
          ),
          home: Scaffold(
            body: Form(
              child: SetCard(
                index: 0,
                set: provider.sets[0],
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      tester.widget<TextField>(find.byType(TextField).first).readOnly,
      false,
    );

    await tester.enterText(find.byType(TextFormField).first, '10');
    await tester.enterText(find.byType(TextFormField).at(1), '5');

    // Open keypad then toggle while open
    await tester.tap(find.byType(TextFormField).first);
    await tester.pumpAndSettle();
    expect(keypadController.isOpen, true);

    await tester.tap(find.bySemanticsLabel('Complete set'));
    await tester.pumpAndSettle();
    expect(keypadController.isOpen, false);

    expect(provider.completedCount, 1);
    expect(
      tester.widget<TextField>(find.byType(TextField).first).readOnly,
      true,
    );
    // Card keeps gradient background, no explicit color check here.
  });

  testWidgets('Cardio timer start/stop updates duration', (tester) async {
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
      getDevicesForGym: GetDevicesForGym(_FakeRepo([device])),
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

    final keypadController = OverlayNumericKeypadController();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<DeviceProvider>.value(value: provider),
          Provider<OverlayNumericKeypadController>.value(
            value: keypadController,
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => OverlayNumericKeypadHost(
            controller: keypadController,
            outsideTapMode: OutsideTapMode.closeAfterTap,
            child: child!,
          ),
          home: Scaffold(
            body: Form(
              child: SetCard(
                index: 0,
                set: provider.sets[0],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.play_circle));
    await tester.pump(const Duration(seconds: 1));

    final state = tester.state<SetCardState>(find.byType(SetCard));
    state.stopTimerIfRunning();
    await tester.pumpAndSettle();

    expect(provider.sets[0]['duration'], isNotEmpty);
  });
}
