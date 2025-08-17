import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/muscle_group_provider.dart';
import 'package:tapem/features/muscle_group/domain/models/muscle_group.dart';
import 'package:tapem/features/device/presentation/widgets/exercise_bottom_sheet.dart';
import 'package:tapem/features/device/presentation/widgets/muscle_chips.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/core/providers/auth_provider.dart';
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

class _FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  String? get userId => 'user1';
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final groups = [
    MuscleGroup(id: '1', name: 'Latissimus dorsi', region: MuscleRegion.lats),
  ];

  testWidgets('preview updates when selecting muscle groups', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MuscleGroupProvider>.value(
            value: FakeMuscleGroupProvider(groups),
          ),
          ChangeNotifierProvider<AuthProvider>.value(
            value: _FakeAuthProvider(),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ExerciseBottomSheet(
              gymId: 'g1',
              deviceId: 'd1',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No muscle groups available'), findsOneWidget);
    // Category heading should be visible
    expect(find.text('Back'), findsOneWidget);
    await tester.tap(find.text('Latissimus dorsi'));
    await tester.pump();
    expect(find.text('Selected'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(MuscleChips),
        matching: find.text('Latissimus dorsi'),
      ),
      findsOneWidget,
    );
  });
}
