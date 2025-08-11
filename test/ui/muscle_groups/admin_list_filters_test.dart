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
  void applyMuscleAssignments(String deviceId, List<String> primary,
      List<String> secondary) {
    final i = _devices.indexWhere((d) => d.uid == deviceId);
    if (i != -1) {
      _devices[i] = _devices[i].copyWith(
        primaryMuscleGroups: primary,
        secondaryMuscleGroups: secondary,
      );
      notifyListeners();
    }
  }

  @override
  void patchDeviceGroups(
      String deviceId, List<String> primary, List<String> secondary) {}

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
  testWidgets('shows header title', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(create: (_) => FakeAuthProvider()),
          ChangeNotifierProvider<DeviceProvider>(
              create: (_) => FakeDeviceProvider(const [])),
          ChangeNotifierProvider<MuscleGroupProvider>(
              create: (_) => FakeMuscleGroupProvider(const [])),
        ],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const MuscleGroupAdminScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Muskelgruppen verwalten'), findsOneWidget);
  });

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
        name: 'Lats',
        region: MuscleRegion.lats,
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

  testWidgets('reset filter clears search and chips', (tester) async {
    final devices = [
      Device(
        uid: '1',
        id: 1,
        name: 'A',
        description: 'BrandA',
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
        name: 'Lats',
        region: MuscleRegion.lats,
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
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const MuscleGroupAdminScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'A');
    await tester.pumpAndSettle();
    expect(find.text('C'), findsNothing);

    await tester.tap(find.text('Muskel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chest'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('A'), findsOneWidget);

    await tester.tap(find.text('Filter zurücksetzen'));
    await tester.pumpAndSettle();

    expect(find.text('A'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
  });

  testWidgets('card menu reset clears muscle assignments', (tester) async {
    final devices = [
      Device(
        uid: '1',
        id: 1,
        name: 'A',
        description: 'BrandA',
        primaryMuscleGroups: const ['m1'],
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
    ];

    final deviceProv = FakeDeviceProvider(devices);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(create: (_) => FakeAuthProvider()),
          ChangeNotifierProvider<DeviceProvider>(create: (_) => deviceProv),
          ChangeNotifierProvider<MuscleGroupProvider>(
              create: (_) => FakeMuscleGroupProvider(groups)),
        ],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const MuscleGroupAdminScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(deviceProv.devices.first.primaryMuscleGroups, isNotEmpty);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Muskelgruppen zurücksetzen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Muskelgruppen zurücksetzen'));
    await tester.pumpAndSettle();

    expect(deviceProv.devices.first.primaryMuscleGroups, isEmpty);
    expect(find.text('Chest'), findsNothing);
  });
}
