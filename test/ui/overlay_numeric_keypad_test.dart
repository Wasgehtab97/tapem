import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/ui/numeric_keypad/overlay_numeric_keypad.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/device_provider.dart';
import 'package:tapem/features/device/domain/repositories/device_repository.dart';
import 'package:tapem/features/device/domain/models/device.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tapem/features/device/domain/models/device_session_snapshot.dart';
import 'package:tapem/services/membership_service.dart';

class _FakeDeviceRepository implements DeviceRepository {
  @override
  Future<List<Device>> getDevicesForGym(String gymId) async => [];
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
  Future<List<DeviceSessionSnapshot>> fetchSessionSnapshotsPaginated({required String gymId, required String deviceId, required String userId, required int limit, String? exerciseId, DocumentSnapshot? startAfter,}) async => <DeviceSessionSnapshot>[];
  @override
  Future<DeviceSessionSnapshot?> getSnapshotBySessionId({required String gymId, required String deviceId, required String sessionId,}) async => null;
  @override
  DocumentSnapshot? get lastSnapshotCursor => null;
}

class _FakeMembershipService implements MembershipService {
  @override
  Future<void> ensureMembership(String gymId, String uid) async {}
}

void main() {
  testWidgets('Overlay keypad inputs and backspace works', (tester) async {
    final controller = OverlayNumericKeypadController();
    final textCtrl = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: OverlayNumericKeypadHost(
          controller: controller,
          child: TextField(controller: textCtrl),
        ),
      ),
    );

    controller.openFor(textCtrl);
    await tester.pumpAndSettle();

    expect(find.byType(OverlayNumericKeypad), findsOneWidget);

    // viewInsets.bottom should stay at 0 while overlay is visible
    final hostCtx = tester.element(find.byType(OverlayNumericKeypadHost));
    expect(MediaQuery.of(hostCtx).viewInsets.bottom, 0);

    await tester.tap(find.text('1'));
    await tester.pump();
    expect(textCtrl.text, '1');

    await tester.tap(find.byIcon(Icons.backspace_outlined).first);
    await tester.pump();
    expect(textCtrl.text, '');

    await tester.tap(find.byIcon(Icons.keyboard_hide_rounded));
    await tester.pumpAndSettle();
    expect(controller.isOpen, false);
  });

  testWidgets('close with immediate flag removes overlay without delay',
      (tester) async {
    final controller = OverlayNumericKeypadController();
    final textCtrl = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: OverlayNumericKeypadHost(
          controller: controller,
          child: TextField(controller: textCtrl),
        ),
      ),
    );

    controller.openFor(textCtrl);
    await tester.pumpAndSettle();
    expect(find.byType(OverlayNumericKeypad), findsOneWidget);

    controller.close(immediate: true);
    await tester.pump();

    expect(find.byType(OverlayNumericKeypad), findsNothing);
  });

  testWidgets('allowDecimal parameter sets controller flag', (tester) async {
    final controller = OverlayNumericKeypadController();
    final textCtrl = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: OverlayNumericKeypadHost(
          controller: controller,
          child: const SizedBox.shrink(),
        ),
      ),
    );

    controller.openFor(textCtrl, allowDecimal: false);
    await tester.pump();

    expect(controller.allowDecimal, false);
  });

  testWidgets('outside tap triggers button and closes keypad immediately',
      (tester) async {
    final controller = OverlayNumericKeypadController();
    bool pressed = false;
    final textCtrl = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: OverlayNumericKeypadHost(
          controller: controller,
          outsideTapMode: OutsideTapMode.closeAfterTap,
          child: Scaffold(
            body: Column(
              children: [
                TextField(controller: textCtrl, readOnly: true, onTap: () {
                  controller.openFor(textCtrl);
                }),
                TextButton(
                  onPressed: () => pressed = true,
                  child: const Text('Add'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    controller.openFor(textCtrl);
    await tester.pumpAndSettle();
    expect(controller.isOpen, true);

    final gesture =
        await tester.startGesture(tester.getCenter(find.text('Add')));
    await tester.pump();
    expect(controller.isOpen, false);

    await gesture.up();
    await tester.pumpAndSettle();

    expect(pressed, true);
    expect(controller.isOpen, false);
  });

  testWidgets('check button closes overlay when all sets done', (tester) async {
    final controller = OverlayNumericKeypadController();
    final textCtrl = TextEditingController();
    final provider = DeviceProvider(
      firestore: FakeFirebaseFirestore(),
      deviceRepository: _FakeDeviceRepository(),
      membership: _FakeMembershipService(),
    );
    provider.addSet();
    provider.updateSet(0, weight: '10', reps: '5');

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<DeviceProvider>.value(
          value: provider,
          child: OverlayNumericKeypadHost(
            controller: controller,
            child: TextField(controller: textCtrl),
          ),
        ),
      ),
    );

    controller.openFor(textCtrl);
    await tester.pumpAndSettle();
    expect(controller.isOpen, true);

    await tester.tap(find.byIcon(Icons.check_rounded));
    await tester.pump();

    expect(provider.sets.first['done'], true);
    expect(controller.isOpen, false);
  });
}

