import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/device_provider.dart';
import 'package:tapem/features/device/domain/models/device.dart';
import 'package:tapem/features/device/domain/usecases/get_devices_for_gym.dart';
import 'package:tapem/features/device/presentation/widgets/set_card.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/services/membership_service.dart';
import 'package:tapem/ui/numeric_keypad/overlay_numeric_keypad.dart';
import 'package:tapem/features/device/domain/repositories/device_repository.dart';

class _FakeRepo implements DeviceRepository {
  final List<Device> devices;
  _FakeRepo(this.devices);
  @override
  Future<List<Device>> getDevicesForGym(String gymId) async => devices;
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMembership implements MembershipService {
  @override
  Future<void> ensureMembership(String gymId, String uid) async {}
}

Future<void> _pumpStates(WidgetTester tester, ThemeData theme) async {
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
    membership: _FakeMembership(),
  );
  await provider.loadDevice(
    gymId: 'g1',
    deviceId: 'c1',
    exerciseId: 'ex1',
    userId: 'u1',
  );
  provider.updateSet(0, speed: '10');
  provider.addSet();
  provider.updateSet(1, speed: '10');
  provider.addSet();
  provider.updateSet(2, speed: '10');

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
        theme: theme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => OverlayNumericKeypadHost(
          controller: keypadController,
          outsideTapMode: OutsideTapMode.closeAfterTap,
          child: child!,
        ),
        home: Scaffold(
          body: Column(
            children: [
              SetCard(index: 0, set: provider.sets[0]),
              SetCard(index: 1, set: provider.sets[1]),
              SetCard(index: 2, set: provider.sets[2]),
            ],
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.byIcon(Icons.play_circle).at(1));
  await tester.pump(const Duration(seconds: 1));
  await tester.tap(find.byIcon(Icons.play_circle).at(2));
  await tester.pump(const Duration(seconds: 1));
  await tester.tap(find.byIcon(Icons.stop_circle).at(2));
  await tester.pump();
}

void main() {
  testWidgets('set card timer golden light', (tester) async {
    await _pumpStates(tester, ThemeData.light());
    await expectLater(
      find.byType(Column),
      matchesGoldenFile('goldens/set_card_timer_light.png'),
    );
  }, skip: true);

  testWidgets('set card timer golden dark', (tester) async {
    await _pumpStates(tester, ThemeData.dark());
    await expectLater(
      find.byType(Column),
      matchesGoldenFile('goldens/set_card_timer_dark.png'),
    );
  }, skip: true);
}
