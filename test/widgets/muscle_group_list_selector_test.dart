import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/muscle_group_provider.dart';
import 'package:tapem/features/muscle_group/domain/models/muscle_group.dart';
import 'package:tapem/features/muscle_group/domain/repositories/muscle_group_repository.dart';
import 'package:tapem/features/muscle_group/domain/usecases/delete_muscle_group.dart';
import 'package:tapem/features/muscle_group/domain/usecases/get_muscle_groups_for_gym.dart';
import 'package:tapem/features/muscle_group/domain/usecases/save_muscle_group.dart';
import 'package:tapem/features/history/domain/usecases/get_history_for_device.dart';
import 'package:tapem/features/device/domain/usecases/update_device_muscle_groups_usecase.dart';
import 'package:tapem/features/device/domain/usecases/set_device_muscle_groups_usecase.dart';
import 'package:tapem/features/device/domain/repositories/device_repository.dart';
import 'package:tapem/features/history/domain/models/workout_log.dart';
import 'package:tapem/features/device/domain/models/device.dart';
import 'package:tapem/ui/muscles/muscle_group_list_selector.dart';
import 'package:tapem/l10n/app_localizations.dart';

class _FakeMuscleGroupRepo implements MuscleGroupRepository {
  final List<MuscleGroup> groups;
  _FakeMuscleGroupRepo(this.groups);
  @override
  Future<List<MuscleGroup>> getMuscleGroups(String gymId) async => groups;
  @override
  Future<void> saveMuscleGroup(String gymId, MuscleGroup group) async {}
  @override
  Future<void> deleteMuscleGroup(String gymId, String groupId) async {}
  @override
  Future<String> ensureRegionGroup(String gymId, MuscleRegion region) async => '${region.name}-id';
}

class _FakeHistoryRepo implements GetHistoryForDeviceRepository {
  @override
  Future<List<WorkoutLog>> getHistory({
    required String gymId,
    required String deviceId,
    required String userId,
    String? exerciseId,
  }) async => [];
}

class _FakeDeviceRepo implements DeviceRepository {
  @override
  Future<void> createDevice(String gymId, Device device) async {}
  @override
  Future<void> deleteDevice(String gymId, String deviceId) async {}
  @override
  Future<Device?> getDeviceByNfcCode(String gymId, String nfcCode) async => null;
  @override
  Future<List<Device>> getDevicesForGym(String gymId) async => [];
  @override
  Future<void> setMuscleGroups(String gymId, String deviceId, List<String> primaryGroups, List<String> secondaryGroups) async {}
  @override
  Future<void> updateMuscleGroups(String gymId, String deviceId, List<String> primaryGroups, List<String> secondaryGroups) async {}

  @override
  Future<void> writeSessionSnapshot(String gymId, DeviceSessionSnapshot snapshot) async {}

  @override
  Future<List<DeviceSessionSnapshot>> fetchSessionSnapshotsPaginated({
    required String gymId,
    required String deviceId,
    required int limit,
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

class _FakeMuscleGroupProvider extends MuscleGroupProvider {
  final List<MuscleGroup> _groups;
  _FakeMuscleGroupProvider(this._groups)
      : super(
          getGroups: GetMuscleGroupsForGym(_FakeMuscleGroupRepo(_groups)),
          saveGroup: SaveMuscleGroup(_FakeMuscleGroupRepo(_groups)),
          deleteGroup: DeleteMuscleGroup(_FakeMuscleGroupRepo(_groups)),
          getHistory: GetHistoryForDevice(_FakeHistoryRepo()),
          updateDeviceGroups: UpdateDeviceMuscleGroupsUseCase(_FakeDeviceRepo()),
          setDeviceGroups: SetDeviceMuscleGroupsUseCase(_FakeDeviceRepo()),
        );
  @override
  bool get isLoading => false;
  @override
  List<MuscleGroup> get groups => _groups;
  @override
  Future<void> loadGroups(BuildContext context) async {}
}

void main() {
  final groups = [
    MuscleGroup(id: '1', name: 'Chest', region: MuscleRegion.chest),
    MuscleGroup(id: '2', name: 'Lats', region: MuscleRegion.lats),
  ];

  testWidgets('tap on selected chip deselects', (tester) async {
    List<String> p = [];
    List<String> s = [];
    await tester.pumpWidget(
      ChangeNotifierProvider<MuscleGroupProvider>.value(
        value: _FakeMuscleGroupProvider(groups),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: MuscleGroupListSelector(
              initialPrimary: const [],
              initialSecondary: const [],
              onChanged: (pri, sec) {
                p = pri;
                s = sec;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lats'));
    await tester.pumpAndSettle();
    expect(p, ['2']);
    await tester.tap(find.text('Lats'));
    await tester.pumpAndSettle();
    expect(p, isEmpty);
    expect(s, isEmpty);
  });

  testWidgets('clear all empties both lists', (tester) async {
    List<String> p = [];
    List<String> s = [];
    await tester.pumpWidget(
      ChangeNotifierProvider<MuscleGroupProvider>.value(
        value: _FakeMuscleGroupProvider(groups),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: MuscleGroupListSelector(
              initialPrimary: const [],
              initialSecondary: const [],
              onChanged: (pri, sec) {
                p = pri;
                s = sec;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chest'));
    await tester.tap(find.text('Lats'));
    await tester.pump();
    expect(p, ['1']);
    expect(s, ['2']);
    await tester.tap(find.text('Clear all'));
    await tester.pump();
    expect(p, isEmpty);
    expect(s, isEmpty);
  });

  testWidgets('reset restores initial selection', (tester) async {
    List<String> p = [];
    List<String> s = [];
    await tester.pumpWidget(
      ChangeNotifierProvider<MuscleGroupProvider>.value(
        value: _FakeMuscleGroupProvider(groups),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: MuscleGroupListSelector(
              initialPrimary: const ['1'],
              initialSecondary: const ['2'],
              onChanged: (pri, sec) {
                p = pri;
                s = sec;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lats'));
    await tester.pump();
    expect(p, ['2']);
    expect(s, isEmpty);
    await tester.tap(find.text('Reset'));
    await tester.pump();
    expect(p, ['1']);
    expect(s, ['2']);
  });
}
