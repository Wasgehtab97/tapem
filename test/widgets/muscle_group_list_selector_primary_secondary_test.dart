import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/muscle_group_provider.dart';
import 'package:tapem/features/device/domain/models/device.dart';
import 'package:tapem/features/device/domain/repositories/device_repository.dart';
import 'package:tapem/features/device/domain/usecases/set_device_muscle_groups_usecase.dart';
import 'package:tapem/features/device/domain/usecases/update_device_muscle_groups_usecase.dart';
import 'package:tapem/features/history/domain/models/workout_log.dart';
import 'package:tapem/features/history/domain/usecases/get_history_for_device.dart';
import 'package:tapem/features/muscle_group/domain/models/muscle_group.dart';
import 'package:tapem/features/muscle_group/domain/repositories/muscle_group_repository.dart';
import 'package:tapem/features/muscle_group/domain/usecases/delete_muscle_group.dart';
import 'package:tapem/features/muscle_group/domain/usecases/get_muscle_groups_for_gym.dart';
import 'package:tapem/features/muscle_group/domain/usecases/save_muscle_group.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/ui/muscles/muscle_group_list_selector.dart';

class _FakeMuscleGroupRepo implements MuscleGroupRepository {
  final List<MuscleGroup> groups;
  _FakeMuscleGroupRepo(this.groups);
  @override
  Future<List<MuscleGroup>> getMuscleGroups(String gymId) async => groups;
  @override
  Future<void> saveMuscleGroup(String gymId, MuscleGroup group) async {}
  @override
  Future<void> deleteMuscleGroup(String gymId, String groupId) async {}
}

class _FakeHistoryRepo implements GetHistoryForDeviceRepository {
  @override
  Future<List<WorkoutLog>> getHistory({
    required String gymId,
    required String deviceId,
    required String userId,
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
  Future<void> setMuscleGroups(
      String gymId, String deviceId, List<String> primaryGroups, List<String> secondaryGroups) async {}
  @override
  Future<void> updateMuscleGroups(
      String gymId, String deviceId, List<String> primaryGroups, List<String> secondaryGroups) async {}
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

  @override
  Future<MuscleGroup> getOrCreateByRegion(BuildContext ctx, MuscleRegion region,
      {String? defaultName}) async {
    try {
      return _groups.firstWhere((g) => g.region == region);
    } catch (_) {
      final g = MuscleGroup(
        id: '${region.name}Id',
        name: defaultName ?? region.name,
        region: region,
      );
      _groups.add(g);
      notifyListeners();
      return g;
    }
  }
}

void main() {
  final groups = [
    MuscleGroup(id: 'c1', name: '', region: MuscleRegion.chest),
    MuscleGroup(id: 'chestId', name: 'Chest', region: MuscleRegion.chest),
    MuscleGroup(id: 'b1', name: '', region: MuscleRegion.back),
    MuscleGroup(id: 'backId', name: 'Back', region: MuscleRegion.back),
  ];

  testWidgets('handles primary/secondary selection and on-demand creation',
      (tester) async {
    List<String> changed = [];

    await tester.pumpWidget(
      ChangeNotifierProvider<MuscleGroupProvider>.value(
        value: _FakeMuscleGroupProvider(groups),
        child: MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.green).copyWith(
              primary: Colors.green,
              onPrimary: Colors.white,
              tertiary: Colors.blueAccent,
            ),
          ),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: MuscleGroupListSelector(
              initialSelection: const [],
              onChanged: (ids) => changed = ids,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(InkWell), findsNWidgets(6));

    final backTile = find.widgetWithText(InkWell, 'Back');
    await tester.tap(backTile);
    await tester.pumpAndSettle();
    final backCheckbox =
        find.descendant(of: backTile, matching: find.byType(Checkbox));
    var color =
        (tester.widget<Checkbox>(backCheckbox).fillColor!).resolve({MaterialState.selected});
    expect(color, Colors.green);

    final chestTile = find.widgetWithText(InkWell, 'Chest');
    await tester.tap(chestTile);
    await tester.pumpAndSettle();
    final chestCheckbox =
        find.descendant(of: chestTile, matching: find.byType(Checkbox));
    color = (tester.widget<Checkbox>(chestCheckbox).fillColor!)
        .resolve({MaterialState.selected});
    expect(color, Colors.blueAccent);

    await tester.longPress(chestTile);
    await tester.pumpAndSettle();

    final chestColor =
        (tester.widget<Checkbox>(chestCheckbox).fillColor!).resolve({MaterialState.selected});
    final backColor =
        (tester.widget<Checkbox>(backCheckbox).fillColor!).resolve({MaterialState.selected});
    expect(chestColor, Colors.green);
    expect(backColor, Colors.blueAccent);
    expect(changed, ['chestId', 'backId']);

    final armsTile = find.widgetWithText(InkWell, 'Arms');
    await tester.tap(armsTile);
    await tester.pumpAndSettle();
    expect(changed, ['chestId', 'backId', 'armsId']);
  });
}

