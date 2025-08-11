import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/device_provider.dart';
import 'package:tapem/core/providers/muscle_group_provider.dart';
import 'package:tapem/features/device/domain/models/device.dart';
import 'package:tapem/features/muscle_group/domain/models/muscle_group.dart';
import 'package:tapem/features/muscle_group/presentation/screens/muscle_group_admin_screen.dart';
import 'package:tapem/l10n/app_localizations.dart';

class FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  String? get gymCode => 'g1';
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeDeviceProvider extends ChangeNotifier implements DeviceProvider {
  final List<Device> _devices;
  FakeDeviceProvider(this._devices);
  @override
  List<Device> get devices => _devices;
  @override
  bool get isLoading => false;
  @override
  Future<void> loadDevices(String gymId) async {}
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeMuscleGroupProvider extends ChangeNotifier
    implements MuscleGroupProvider {
  final List<MuscleGroup> _groups;
  FakeMuscleGroupProvider(this._groups);
  @override
  bool get isLoading => false;
  @override
  String? get error => null;
  @override
  List<MuscleGroup> get groups => _groups;
  @override
  Map<String, int> get counts => {};
  @override
  Future<void> loadGroups(BuildContext context) async {}
  @override
  Future<void> updateDeviceAssignments(BuildContext context, String deviceId,
          List<String> primaryGroupIds, List<String> secondaryGroupIds) async {}
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('lists non-multi devices and filters by muscle', (tester) async {
    final devices = [
      Device(
        uid: '1',
        id: 1,
        name: 'A',
        description: 'BrandA',
        primaryMuscleGroups: const ['m1'],
      ),
      Device(
        uid: '2',
        id: 2,
        name: 'B',
        description: 'BrandB',
        isMulti: true,
        primaryMuscleGroups: const ['m1'],
      ),
      Device(
        uid: '3',
        id: 3,
        name: 'C',
        description: 'BrandC',
        primaryMuscleGroups: const ['m2'],
      ),
    ];

    final groups = [
      MuscleGroup(
        id: 'm1',
        name: 'Chest',
        region: MuscleRegion.chest,
        primaryDeviceIds: const [],
        secondaryDeviceIds: const [],
        exerciseIds: const [],
      ),
      MuscleGroup(
        id: 'm2',
        name: 'Back',
        region: MuscleRegion.back,
        primaryDeviceIds: const [],
        secondaryDeviceIds: const [],
        exerciseIds: const [],
      ),
    ];

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(create: (_) => FakeAuthProvider()),
          ChangeNotifierProvider<DeviceProvider>(
              create: (_) => FakeDeviceProvider(devices)),
          ChangeNotifierProvider<MuscleGroupProvider>(
              create: (_) => FakeMuscleGroupProvider(groups)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const MuscleGroupAdminScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('A'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
    expect(find.text('B'), findsNothing);

    await tester.tap(find.text('Muskel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chest'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('A'), findsOneWidget);
    expect(find.text('C'), findsNothing);

    await tester.tap(find.text('A'));
    await tester.pumpAndSettle();
    expect(find.text('A – Muskelgruppen'), findsOneWidget);
  });
}
