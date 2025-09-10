import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tapem/ui/muscles/muscle_group_selector.dart';
import 'package:tapem/features/muscle_group/domain/models/muscle_group.dart';
import 'package:tapem/core/providers/muscle_group_provider.dart';
import 'package:tapem/features/muscle_group/domain/repositories/muscle_group_repository.dart';
import 'package:tapem/features/muscle_group/domain/usecases/get_muscle_groups_for_gym.dart';
import 'package:tapem/features/muscle_group/domain/usecases/save_muscle_group.dart';
import 'package:tapem/features/muscle_group/domain/usecases/delete_muscle_group.dart';
import 'package:tapem/features/history/domain/usecases/get_history_for_device.dart';
import 'package:tapem/features/device/domain/usecases/update_device_muscle_groups_usecase.dart';
import 'package:tapem/features/device/domain/usecases/set_device_muscle_groups_usecase.dart';
import 'package:tapem/features/device/domain/repositories/device_repository.dart';
import 'package:tapem/features/history/domain/models/workout_log.dart';
import 'package:tapem/features/device/domain/models/device.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/features/device/domain/models/device_session_snapshot.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  Future<String> ensureRegionGroup(String gymId, MuscleRegion region) async =>
      '${region.name}-id';
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

class FakeMuscleGroupProvider extends MuscleGroupProvider {
  final List<MuscleGroup> _groups;
  FakeMuscleGroupProvider(this._groups)
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

  testWidgets('MuscleGroupSelector shows names and toggles', (tester) async {
    List<String> selected = [];
    await tester.pumpWidget(
      ChangeNotifierProvider<MuscleGroupProvider>.value(
        value: FakeMuscleGroupProvider(groups),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: MuscleGroupSelector(
              initialSelection: const [],
              onChanged: (ids) => selected = ids,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Chest'), findsOneWidget);
    await tester.tap(find.text('Chest'));
    await tester.pumpAndSettle();
    expect(selected, ['1']);
  });

  testWidgets('Save button disabled until name and group selected', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<MuscleGroupProvider>.value(
        value: FakeMuscleGroupProvider(groups),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _TestWidget(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<TextButton>(find.text('Save')).onPressed, isNull);
    await tester.enterText(find.byType(TextField), 'Pushup');
    await tester.tap(find.text('Chest'));
    await tester.pump();
    expect(tester.widget<TextButton>(find.text('Save')).onPressed, isNotNull);
  });
}

class _TestWidget extends StatefulWidget {
  @override
  State<_TestWidget> createState() => _TestWidgetState();
}

class _TestWidgetState extends State<_TestWidget> {
  List<String> _selected = [];
  final _ctr = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final canSave = _ctr.text.trim().isNotEmpty && _selected.isNotEmpty;
    return Scaffold(
      body: Column(
        children: [
          TextField(controller: _ctr, onChanged: (_) => setState(() {})),
          MuscleGroupSelector(
            initialSelection: _selected,
            onChanged: (ids) => setState(() => _selected = ids),
          ),
          TextButton(onPressed: canSave ? () {} : null, child: const Text('Save')),
        ],
      ),
    );
  }
}
