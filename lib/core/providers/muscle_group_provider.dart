import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import 'package:uuid/uuid.dart';

import "../../main.dart";
import '../providers/auth_provider.dart';
import '../providers/gym_provider.dart';
import '../../features/muscle_group/data/repositories/muscle_group_repository_impl.dart';
import '../../features/muscle_group/data/sources/firestore_muscle_group_source.dart';
import '../../features/muscle_group/domain/models/muscle_group.dart';
import '../../features/muscle_group/domain/usecases/get_muscle_groups_for_gym.dart';
import '../../features/muscle_group/domain/usecases/save_muscle_group.dart';
import '../../features/muscle_group/domain/usecases/delete_muscle_group.dart';
import '../../features/device/domain/usecases/update_device_muscle_groups_usecase.dart';
import '../../features/device/domain/usecases/set_device_muscle_groups_usecase.dart';
import '../../features/device/data/repositories/device_repository_impl.dart';
import '../../features/device/data/sources/firestore_device_source.dart';
import '../../features/history/data/sources/firestore_history_source.dart';
import '../../features/history/data/repositories/history_repository_impl.dart';
import '../../features/history/domain/usecases/get_history_for_device.dart';

class MuscleGroupProvider extends ChangeNotifier {
  final GetMuscleGroupsForGym _getGroups;
  final SaveMuscleGroup _saveGroup;
  final DeleteMuscleGroup _deleteGroup;
  final GetHistoryForDevice _getHistory;
  final UpdateDeviceMuscleGroupsUseCase _updateDeviceGroups;
  final SetDeviceMuscleGroupsUseCase _setDeviceGroups;

  MuscleGroupProvider({
    GetMuscleGroupsForGym? getGroups,
    SaveMuscleGroup? saveGroup,
    DeleteMuscleGroup? deleteGroup,
    GetHistoryForDevice? getHistory,
    UpdateDeviceMuscleGroupsUseCase? updateDeviceGroups,
    SetDeviceMuscleGroupsUseCase? setDeviceGroups,
  }) : _getGroups =
           getGroups ??
           GetMuscleGroupsForGym(
             MuscleGroupRepositoryImpl(FirestoreMuscleGroupSource()),
           ),
       _saveGroup =
           saveGroup ??
           SaveMuscleGroup(
             MuscleGroupRepositoryImpl(FirestoreMuscleGroupSource()),
           ),
       _deleteGroup =
           deleteGroup ??
           DeleteMuscleGroup(
             MuscleGroupRepositoryImpl(FirestoreMuscleGroupSource()),
           ),
       _getHistory =
           getHistory ??
           GetHistoryForDevice(HistoryRepositoryImpl(FirestoreHistorySource())),
       _updateDeviceGroups =
           updateDeviceGroups ??
           UpdateDeviceMuscleGroupsUseCase(
             DeviceRepositoryImpl(FirestoreDeviceSource()),
           ),
       _setDeviceGroups =
           setDeviceGroups ??
           SetDeviceMuscleGroupsUseCase(
             DeviceRepositoryImpl(FirestoreDeviceSource()),
           );

  bool _isLoading = false;
  String? _error;
  List<MuscleGroup> _groups = [];
  final Map<String, int> _counts = {};

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<MuscleGroup> get groups => List.unmodifiable(_groups);
  Map<String, int> get counts => Map.unmodifiable(_counts);

  Future<void> loadGroups(BuildContext context) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final gymId = auth.gymCode;
      final userId = auth.userId;
      if (gymId == null || userId == null) {
        throw Exception('Benutzer nicht eingeloggt');
      }

      _groups = await _getGroups.execute(gymId);
      await _loadCounts(gymId, userId);
    } catch (e, st) {
      _error = e.toString();
      debugPrintStack(label: 'MuscleGroupProvider.loadGroups', stackTrace: st);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveGroup(BuildContext context, MuscleGroup group) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final gymId = auth.gymCode;
    if (gymId == null) return;
    await _saveGroup.execute(gymId, group);

    final devices = Provider.of<GymProvider>(context, listen: false).devices;
    for (final dId in group.primaryDeviceIds) {
      try {
        final dev = devices.firstWhere((d) => d.uid == dId);
        if (!dev.isMulti) {
          await _updateDeviceGroups.execute(gymId, dId, [
            group.region.name,
          ], const []);
        }
      } catch (_) {}
    }

    for (final dId in group.secondaryDeviceIds) {
      try {
        final dev = devices.firstWhere((d) => d.uid == dId);
        if (!dev.isMulti) {
          await _updateDeviceGroups.execute(gymId, dId, const [], [
            group.region.name,
          ]);
        }
      } catch (_) {}
    }

    await loadGroups(context);
  }

  Future<void> deleteGroup(BuildContext context, String groupId) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final gymId = auth.gymCode;
    if (gymId == null) return;
    await _deleteGroup.execute(gymId, groupId);
    await loadGroups(context);
  }

  Future<MuscleGroup> getOrCreateByRegion(
    BuildContext ctx,
    MuscleRegion region, {
    String? defaultName,
  }) async {
    final existing = _groups.firstWhereOrNull((g) => g.region == region);
    if (existing != null) return existing;
    final g = MuscleGroup(
      id: const Uuid().v4(),
      name: defaultName ?? region.toString(),
      region: region,
      primaryDeviceIds: const [],
      secondaryDeviceIds: const [],
      exerciseIds: const [],
    );
    await saveGroup(ctx, g);
    await loadGroups(ctx);
    return _groups.firstWhereOrNull((x) => x.id == g.id) ?? g;
  }

  Future<void> assignDevice(
    BuildContext context,
    String deviceId,
    List<String> groupIds,
  ) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final gymId = auth.gymCode;
    if (gymId == null) return;
    for (final g in _groups) {
      if (groupIds.contains(g.id) && !g.primaryDeviceIds.contains(deviceId)) {
        final updated = g.copyWith(
          primaryDeviceIds: [...g.primaryDeviceIds, deviceId],
        );
        await _saveGroup.execute(gymId, updated);
      }
    }
    await loadGroups(context);
  }

  Future<void> assignExercise(
    BuildContext context,
    String exerciseId,
    List<String> groupIds,
  ) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final gymId = auth.gymCode;
    if (gymId == null) return;
    for (final g in _groups) {
      if (groupIds.contains(g.id) && !g.exerciseIds.contains(exerciseId)) {
        final updated = g.copyWith(exerciseIds: [...g.exerciseIds, exerciseId]);
        await _saveGroup.execute(gymId, updated);
      }
    }
    await loadGroups(context);
  }

  Future<void> updateDeviceAssignments(
    BuildContext context,
    String deviceId,
    List<String> primaryGroupIds,
    List<String> secondaryGroupIds,
  ) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final gymId = auth.gymCode;
    if (gymId == null) return;

    for (final g in _groups) {
      final isPrimary = primaryGroupIds.contains(g.id);
      final isSecondary = secondaryGroupIds.contains(g.id);

      if (!isPrimary && !isSecondary) {
        if (!g.primaryDeviceIds.contains(deviceId) &&
            !g.secondaryDeviceIds.contains(deviceId)) {
          continue;
        }
      }

      final newPrimary = List<String>.from(g.primaryDeviceIds);
      final newSecondary = List<String>.from(g.secondaryDeviceIds);
      newPrimary.remove(deviceId);
      newSecondary.remove(deviceId);
      if (isPrimary) newPrimary.add(deviceId);
      if (isSecondary) newSecondary.add(deviceId);

      final updated = g.copyWith(
        primaryDeviceIds: newPrimary,
        secondaryDeviceIds: newSecondary,
      );
      await _saveGroup.execute(gymId, updated);
    }

    await _setDeviceGroups.execute(
      gymId,
      deviceId,
      primaryGroupIds.map((id) {
        final g = _groups.firstWhere((e) => e.id == id);
        return g.region.name;
      }).toList(),
      secondaryGroupIds.map((id) {
        final g = _groups.firstWhere((e) => e.id == id);
        return g.region.name;
      }).toList(),
    );

    await loadGroups(context);
  }

  Future<void> _loadCounts(String gymId, String userId) async {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    _counts.clear();
    for (final group in _groups) {
      int sum = 0;
      for (final dId in group.deviceIds) {
        final logs = await _getHistory.execute(
          gymId: gymId,
          deviceId: dId,
          userId: userId,
        );
        sum += logs.length;
      }
      _counts[group.id] = sum;
    }
  }
}
