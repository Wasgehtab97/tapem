import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/device_provider.dart';
import 'package:tapem/features/device/presentation/widgets/set_card.dart';
import 'package:tapem/features/device/domain/usecases/get_devices_for_gym.dart';
import 'package:tapem/features/device/domain/repositories/device_repository.dart';
import 'package:tapem/features/device/domain/models/device.dart';

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
  testWidgets('SetCard toggle locks fields and colors', (tester) async {
    final provider = DeviceProvider(
      firestore: FakeFirebaseFirestore(),
      getDevicesForGym: GetDevicesForGym(_FakeRepo()),
      log: (_, [__]) {},
    );
    provider.addSet();

    await tester.pumpWidget(
      ChangeNotifierProvider<DeviceProvider>.value(
        value: provider,
        child: MaterialApp(
          home: Scaffold(
            body: Form(
              child: SetCard(index: 0, set: provider.sets[0]),
            ),
          ),
        ),
      ),
    );

    expect(
      tester.widget<TextFormField>(find.byType(TextFormField).first).readOnly,
      false,
    );

    await tester.enterText(find.byType(TextFormField).first, '10');
    await tester.enterText(find.byType(TextFormField).at(1), '5');
    await tester.tap(find.byIcon(Icons.check_circle_outline));
    await tester.pumpAndSettle();

    expect(provider.completedCount, 1);
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField).first).readOnly,
      true,
    );
    final container = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
    final box = container.decoration as BoxDecoration;
    expect(box.color, Colors.green.withOpacity(0.1));
  });
}
