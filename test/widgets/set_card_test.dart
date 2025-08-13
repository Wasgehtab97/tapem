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

class _FakeRepo implements DeviceRepository {
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
}

void main() {
  testWidgets('SetCard toggle locks fields', (tester) async {
    final provider = DeviceProvider(
      firestore: FakeFirebaseFirestore(),
      getDevicesForGym: GetDevicesForGym(_FakeRepo()),
      log: (_, [__]) {},
    );
    provider.addSet();

    final keypadController = OverlayNumericKeypadController();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<DeviceProvider>.value(value: provider),
          ChangeNotifierProvider<OverlayNumericKeypadController>.value(
            value: keypadController,
          ),
        ],
        child: OverlayNumericKeypadHost(
          controller: keypadController,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
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
      ),
    );

    expect(
      tester.widget<TextField>(find.byType(TextField).first).readOnly,
      false,
    );

    await tester.enterText(find.byType(TextFormField).first, '10');
    await tester.enterText(find.byType(TextFormField).at(1), '5');
    await tester.tap(find.bySemanticsLabel('Complete set'));
    await tester.pumpAndSettle();

    expect(provider.completedCount, 1);
    expect(
      tester.widget<TextField>(find.byType(TextField).first).readOnly,
      true,
    );
    // Card keeps gradient background, no explicit color check here.
  });
}
