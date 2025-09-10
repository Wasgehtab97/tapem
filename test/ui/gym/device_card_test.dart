import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tapem/features/device/domain/models/device.dart';
import 'package:tapem/ui/devices/device_card.dart';
import 'package:tapem/features/device/presentation/widgets/muscle_chips.dart';
import 'package:tapem/core/providers/muscle_group_provider.dart';
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
import 'package:tapem/features/device/domain/models/device_session_snapshot.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

MuscleGroupProvider _makeProvider() {
  final repo = _DummyMuscleGroupRepo();
  return MuscleGroupProvider(
    getGroups: GetMuscleGroupsForGym(repo),
    saveGroup: SaveMuscleGroup(repo),
    deleteGroup: DeleteMuscleGroup(repo),
    getHistory: GetHistoryForDevice(_FakeHistoryRepo()),
    updateDeviceGroups: UpdateDeviceMuscleGroupsUseCase(_DummyDeviceRepo()),
    setDeviceGroups: SetDeviceMuscleGroupsUseCase(_DummyDeviceRepo()),
  );
}

void main() {
  testWidgets('renders name, brand and id', (tester) async {
    final device = Device(uid: '1', id: 1, name: 'Bench', description: 'Eleiko');
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => _makeProvider(),
          child: DeviceCard(device: device),
        ),
      ),
    );
    expect(find.text('Bench'), findsOneWidget);
    expect(find.text('Eleiko'), findsOneWidget);
    expect(find.text('ID: 1'), findsOneWidget);
  });

  testWidgets('shows chips when not multi', (tester) async {
    final device = Device(
      uid: '1',
      id: 1,
      name: 'Bench',
      description: 'Eleiko',
      primaryMuscleGroups: const ['chest'],
      secondaryMuscleGroups: const ['back'],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => _makeProvider(),
          child: DeviceCard(device: device),
        ),
      ),
    );
    expect(find.byType(MuscleChips), findsOneWidget);
  });

  testWidgets('hides chips when multi', (tester) async {
    final device = Device(
      uid: '1',
      id: 1,
      name: 'Multi',
      description: 'Eleiko',
      isMulti: true,
      primaryMuscleGroups: const ['chest'],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => _makeProvider(),
          child: DeviceCard(device: device),
        ),
      ),
    );
    expect(find.byType(MuscleChips), findsNothing);
  });

  testWidgets('orders primary then secondary chips with styles', (tester) async {
    final device = Device(
      uid: '1',
      id: 1,
      name: 'Bench',
      description: 'Eleiko',
      primaryMuscleGroups: const ['chest'],
      secondaryMuscleGroups: const ['back'],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => _makeProvider(),
          child: DeviceCard(device: device),
        ),
      ),
    );
    final chips = tester.widgetList<Chip>(find.byType(Chip)).toList();
    final context = tester.element(find.byType(DeviceCard));
    final theme = Theme.of(context);
    expect((chips[0].label as Text).data, 'Chest');
    expect(chips[0].backgroundColor, theme.colorScheme.primary);
    expect((chips[1].label as Text).data, 'Back');
    final shape = chips[1].shape as StadiumBorder;
    expect(shape.side.color, theme.colorScheme.tertiary);
  });
}

