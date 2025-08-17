import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/muscle_group_provider.dart';
import 'package:tapem/features/device/domain/models/device.dart';
import 'package:tapem/features/muscle_group/domain/models/muscle_group.dart';
import 'package:tapem/features/muscle_group/domain/repositories/muscle_group_repository.dart';
import 'package:tapem/features/muscle_group/domain/usecases/get_muscle_groups_for_gym.dart';
import 'package:tapem/features/muscle_group/domain/usecases/save_muscle_group.dart';
import 'package:tapem/features/muscle_group/domain/usecases/delete_muscle_group.dart';
import 'package:tapem/features/history/domain/usecases/get_history_for_device.dart';
import 'package:tapem/features/history/domain/models/workout_log.dart';
import 'package:tapem/features/device/domain/repositories/device_repository.dart';
import 'package:tapem/features/device/domain/usecases/update_device_muscle_groups_usecase.dart';
import 'package:tapem/features/device/domain/usecases/set_device_muscle_groups_usecase.dart';
import 'package:tapem/ui/common/search_and_filters.dart';

class _DummyMuscleGroupRepo implements MuscleGroupRepository {
  @override
  Future<void> deleteMuscleGroup(String gymId, String groupId) async {}

  @override
  Future<List<MuscleGroup>> getMuscleGroups(String gymId) async => [];

  @override
  Future<void> saveMuscleGroup(String gymId, MuscleGroup group) async {}

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

class _DummyDeviceRepo implements DeviceRepository {
  @override
  Future<void> createDevice(String gymId, Device device) async {}

  @override
  Future<void> deleteDevice(String gymId, String deviceId) async {}

  @override
  Future<Device?> getDeviceByNfcCode(String gymId, String nfcCode) async => null;

  @override
  Future<List<Device>> getDevicesForGym(String gymId) async => [];

  @override
  Future<void> updateMuscleGroups(String gymId, String deviceId, List<String> primaryGroups, List<String> secondaryGroups) async {}

  @override
  Future<void> setMuscleGroups(String gymId, String deviceId, List<String> primaryGroups, List<String> secondaryGroups) async {}

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

class _TestMuscleGroupProvider extends MuscleGroupProvider {
  final List<MuscleGroup> _groupsOverride;
  _TestMuscleGroupProvider(this._groupsOverride)
      : super(
          getGroups: GetMuscleGroupsForGym(_DummyMuscleGroupRepo()),
          saveGroup: SaveMuscleGroup(_DummyMuscleGroupRepo()),
          deleteGroup: DeleteMuscleGroup(_DummyMuscleGroupRepo()),
          getHistory: GetHistoryForDevice(_FakeHistoryRepo()),
          updateDeviceGroups: UpdateDeviceMuscleGroupsUseCase(_DummyDeviceRepo()),
          setDeviceGroups: SetDeviceMuscleGroupsUseCase(_DummyDeviceRepo()),
        );
  @override
  List<MuscleGroup> get groups => _groupsOverride;
}

class _Harness extends StatefulWidget {
  const _Harness();
  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  String query = '';
  SortOrder sort = SortOrder.az;
  Set<String> muscles = {};
  final devices = [
    Device(uid: '1', id: 1, name: 'Alpha', primaryMuscleGroups: const ['chest'], description: ''),
    Device(uid: '2', id: 2, name: 'Beta', primaryMuscleGroups: const ['legs'], description: ''),
  ];
  @override
  Widget build(BuildContext context) {
    final filtered = devices.where((d) {
      final matchesName = d.name.toLowerCase().contains(query.toLowerCase());
      if (d.isMulti || muscles.isEmpty) {
        return matchesName;
      }
      final all = {...d.primaryMuscleGroups, ...d.secondaryMuscleGroups};
      return matchesName && all.any(muscles.contains);
    }).toList()
      ..sort((a, b) => sort == SortOrder.az ? a.name.compareTo(b.name) : b.name.compareTo(a.name));
    return Column(
      children: [
        SearchAndFilters(
          query: query,
          onQuery: (v) => setState(() => query = v),
          sort: sort,
          onSort: (v) => setState(() => sort = v),
          muscleFilterIds: muscles,
          onMuscleFilter: (v) => setState(() => muscles = v),
        ),
        Expanded(
          child: ListView(
            children: [
              for (var i = 0; i < filtered.length; i++)
                Text(filtered[i].name, key: ValueKey('device-$i')),
            ],
          ),
        ),
      ],
    );
  }
}

void main() {
  final groups = [
    MuscleGroup(id: 'chest', name: 'Chest', region: MuscleRegion.chest),
    MuscleGroup(id: 'legs', name: 'Quadriceps', region: MuscleRegion.quadriceps),
  ];
  testWidgets('muscle filter reduces list', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<MuscleGroupProvider>.value(
          value: _TestMuscleGroupProvider(groups),
          child: const Scaffold(body: _Harness()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
    await tester.tap(find.text('Muskel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chest'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsNothing);
  });

  testWidgets('sort name Z→A', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<MuscleGroupProvider>.value(
          value: _TestMuscleGroupProvider(groups),
          child: const Scaffold(body: _Harness()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Name'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Z→A'));
    await tester.pumpAndSettle();
    final first = tester.widget<Text>(find.byKey(const ValueKey('device-0')));
    expect(first.data, 'Beta');
  });
}

