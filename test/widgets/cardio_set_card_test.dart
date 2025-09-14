import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/device_provider.dart';
import 'package:tapem/features/device/domain/models/device.dart';
import 'package:tapem/features/device/domain/repositories/device_repository.dart';
import 'package:tapem/features/device/domain/usecases/get_devices_for_gym.dart';
import 'package:tapem/features/device/presentation/widgets/set_card.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/services/membership_service.dart';

class _Repo implements DeviceRepository {
  final List<Device> devices;
  _Repo(this.devices);
  @override
  Future<List<Device>> getDevicesForGym(String gymId) async => devices;
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Membership implements MembershipService {
  @override
  Future<void> ensureMembership(String gymId, String uid) async {}
}

void main() {
  testWidgets('valid speed passes validation', (tester) async {
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
      getDevicesForGym: GetDevicesForGym(_Repo([device])),
      log: (_, [__]) {},
      membership: _Membership(),
    );
    await provider.loadDevice(
      gymId: 'g1',
      deviceId: 'c1',
      exerciseId: 'ex1',
      userId: 'u1',
    );
    provider.updateSet(0, speed: '10');
    await tester.pumpWidget(
      ChangeNotifierProvider<DeviceProvider>.value(
        value: provider,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Form(
            child: SetCard(index: 0, set: provider.sets[0], readOnly: false),
          ),
        ),
      ),
    );
    final form = tester.state<FormState>(find.byType(Form));
    expect(form.validate(), true);
  });
}
