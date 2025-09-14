import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/exercise_provider.dart';
import 'package:tapem/core/providers/muscle_group_provider.dart';
import 'package:tapem/features/device/domain/models/exercise.dart';
import 'package:tapem/features/device/domain/repositories/exercise_repository.dart';
import 'package:tapem/features/device/domain/usecases/create_exercise_usecase.dart';
import 'package:tapem/features/device/domain/usecases/delete_exercise_usecase.dart';
import 'package:tapem/features/device/domain/usecases/get_exercises_for_device.dart';
import 'package:tapem/features/device/domain/usecases/update_exercise_usecase.dart';
import 'package:tapem/features/device/domain/usecases/update_exercise_muscle_groups_usecase.dart';
import 'package:tapem/features/muscle_group/domain/models/muscle_group.dart';
import 'package:tapem/features/muscle_group/domain/repositories/muscle_group_repository.dart';
import 'package:tapem/features/muscle_group/domain/usecases/delete_muscle_group.dart';
import 'package:tapem/features/muscle_group/domain/usecases/get_muscle_groups_for_gym.dart';
import 'package:tapem/features/muscle_group/domain/usecases/save_muscle_group.dart';
import 'package:tapem/features/history/domain/usecases/get_history_for_device.dart';
import 'package:tapem/features/device/domain/usecases/update_device_muscle_groups_usecase.dart';
import 'package:tapem/features/device/domain/usecases/set_device_muscle_groups_usecase.dart';
import 'package:tapem/features/device/domain/repositories/device_repository.dart';
import 'package:tapem/features/device/domain/models/device_session_snapshot.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tapem/features/history/domain/models/workout_log.dart';
import 'package:tapem/features/device/domain/models/device.dart';
import 'package:tapem/features/device/presentation/screens/exercise_list_screen.dart';
import 'package:tapem/l10n/app_localizations.dart';

class _FakeExerciseRepo implements ExerciseRepository {
  List<Exercise> exercises;
  _FakeExerciseRepo(this.exercises);
  @override
  Future<List<Exercise>> getExercises(
          String gymId, String deviceId, String userId) async => exercises;
  @override
  Future<void> createExercise(String gymId, String deviceId, Exercise ex) async {}
  @override
  Future<void> updateExercise(String gymId, String deviceId, Exercise ex) async {}
  @override
  Future<void> deleteExercise(
          String gymId, String deviceId, String exerciseId, String userId) async {}
  @override
  Future<void> updateMuscleGroups(String gymId, String deviceId, String exerciseId,
      List<String> primaryGroups, List<String> secondaryGroups) async {
    final idx = exercises.indexWhere((e) => e.id == exerciseId);
    if (idx != -1) {
      exercises[idx] = exercises[idx].copyWith(
        primaryMuscleGroupIds: primaryGroups,
        secondaryMuscleGroupIds: secondaryGroups,
      );
    }
  }
}

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
  @override
  Future<bool> hasSessionForDate({
    required String gymId,
    required String deviceId,
    required String userId,
    required DateTime date,
  }) async => false;
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

class _FakeAuth extends ChangeNotifier implements AuthProvider {
  @override
  String? get userId => 'u1';
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('chips reflect updated muscle groups', (tester) async {
    final repo = _FakeExerciseRepo([
      Exercise(
        id: 'e1',
        name: 'Ex',
        userId: 'u1',
        primaryMuscleGroupIds: const ['1'],
        secondaryMuscleGroupIds: const ['2'],
      ),
    ]);
    final exerciseProvider = ExerciseProvider(
      getEx: GetExercisesForDevice(repo),
      createEx: CreateExerciseUseCase(repo),
      deleteEx: DeleteExerciseUseCase(repo),
      updateEx: UpdateExerciseUseCase(repo),
      updateMuscles: UpdateExerciseMuscleGroupsUseCase(repo),
    );
    final muscleProv = _FakeMuscleGroupProvider([
      MuscleGroup(id: '1', name: 'Chest', region: MuscleRegion.chest),
      MuscleGroup(id: '2', name: 'Lats', region: MuscleRegion.lats),
      MuscleGroup(id: '3', name: 'Biceps', region: MuscleRegion.biceps),
    ]);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: _FakeAuth()),
          ChangeNotifierProvider<ExerciseProvider>.value(value: exerciseProvider),
          ChangeNotifierProvider<MuscleGroupProvider>.value(value: muscleProv),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ExerciseListScreen(gymId: 'g', deviceId: 'd'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Chest'), findsOneWidget);
    expect(find.text('Lats'), findsOneWidget);
    await exerciseProvider.updateMuscleGroups('g', 'd', 'e1', 'u1', ['3'], []);
    await tester.pumpAndSettle();
    expect(find.text('Biceps'), findsOneWidget);
    expect(find.text('Chest'), findsNothing);
  });
}
