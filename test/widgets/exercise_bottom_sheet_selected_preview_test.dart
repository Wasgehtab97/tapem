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
import 'package:tapem/features/muscle_group/domain/usecases/ensure_region_group.dart';
import 'package:tapem/features/device/domain/repositories/device_repository.dart';
import 'package:tapem/features/history/domain/models/workout_log.dart';
import 'package:tapem/features/device/domain/models/device.dart';
import 'package:tapem/features/device/domain/models/device_session_snapshot.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tapem/services/membership_service.dart';

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

class FakeMembershipService implements MembershipService {
  @override
  Future<void> ensureMembership(String gymId, String uid) {
    return Future.value();
  }
}

class FakeMuscleGroupProvider extends MuscleGroupProvider {
  final List<MuscleGroup> _groups;
  final _FakeMuscleGroupRepo _repo;

  FakeMuscleGroupProvider._(this._groups, this._repo)
      : super(
          getGroups: GetMuscleGroupsForGym(_repo),
          saveGroup: SaveMuscleGroup(_repo),
          deleteGroup: DeleteMuscleGroup(_repo),
          getHistory: GetHistoryForDevice(_FakeHistoryRepo()),
          updateDeviceGroups: UpdateDeviceMuscleGroupsUseCase(_FakeDeviceRepo()),
          setDeviceGroups: SetDeviceMuscleGroupsUseCase(_FakeDeviceRepo()),
          ensureRegionGroup: EnsureRegionGroup(_repo),
          membership: FakeMembershipService(),
        );

  factory FakeMuscleGroupProvider(List<MuscleGroup> groups) {
    final repo = _FakeMuscleGroupRepo(groups);
    return FakeMuscleGroupProvider._(groups, repo);
  }

  @override
  bool get isLoading => false;

  @override
  List<MuscleGroup> get groups => _groups;

  @override
  Future<void> loadGroups(BuildContext context, {bool force = false}) async {}
}

class _FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  String? get userId => 'user1';
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final groups = [
    MuscleGroup(id: '1', name: 'Rücken', region: MuscleRegion.ruecken),
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

    expect(find.text('No muscle groups available'), findsNothing);
    // Category heading should be visible
    expect(find.text('Back'), findsOneWidget);
    await tester.tap(find.text('Rücken'));
    await tester.pump();
    expect(find.text('Selected'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(MuscleChips),
        matching: find.text('Rücken'),
      ),
      findsOneWidget,
    );
  });
}
