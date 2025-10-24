import 'dart:async';

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
import '../providers/device_provider.dart';
import '../../features/muscle_group/domain/usecases/ensure_region_group.dart';
import '../../features/device/domain/usecases/update_device_muscle_groups_usecase.dart';
import '../../features/device/domain/usecases/set_device_muscle_groups_usecase.dart';
import '../../features/device/data/repositories/device_repository_impl.dart';
import '../../features/device/data/sources/firestore_device_source.dart';
import '../../features/history/data/sources/firestore_history_source.dart';
import '../../features/history/data/repositories/history_repository_impl.dart';
import '../../features/history/domain/usecases/get_history_for_device.dart';
import '../../services/membership_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MuscleGroupProvider extends ChangeNotifier {
  final GetMuscleGroupsForGym _getGroups;
  final SaveMuscleGroup _saveGroup;
  final DeleteMuscleGroup _deleteGroup;
  final GetHistoryForDevice _getHistory;
  final UpdateDeviceMuscleGroupsUseCase _updateDeviceGroups;
  final SetDeviceMuscleGroupsUseCase _setDeviceGroups;
  final EnsureRegionGroup _ensureRegionGroup;
  final MembershipService _membership;

  MuscleGroupProvider({
    GetMuscleGroupsForGym? getGroups,
    SaveMuscleGroup? saveGroup,
    DeleteMuscleGroup? deleteGroup,
    GetHistoryForDevice? getHistory,
    UpdateDeviceMuscleGroupsUseCase? updateDeviceGroups,
    SetDeviceMuscleGroupsUseCase? setDeviceGroups,
    EnsureRegionGroup? ensureRegionGroup,
    MembershipService? membership,
  })  : _getGroups =
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
           ),
       _ensureRegionGroup =
           ensureRegionGroup ??
           EnsureRegionGroup(
             MuscleGroupRepositoryImpl(FirestoreMuscleGroupSource()),
           ),
       _membership = membership ?? FirestoreMembershipService();

  bool _isLoading = false;
  String? _error;
  List<MuscleGroup> _groups = [];
  final Map<String, int> _counts = {};
  String? _loadedGymId;
  bool _hasLoadedSuccessfully = false;
  Future<void>? _activeLoad;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<MuscleGroup> get groups => List.unmodifiable(_groups);
  Map<String, int> get counts => Map.unmodifiable(_counts);

  Future<String?> ensureRegionGroup(
      BuildContext context, MuscleRegion region) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final gymId = auth.gymCode;
    if (gymId == null) return null;
    return _ensureRegionGroup.execute(gymId, region);
  }

  Future<void> loadGroups(BuildContext context, {bool force = false}) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final gymId = auth.gymCode;
    final userId = auth.userId;
    if (gymId == null || userId == null) {
      _error = 'Benutzer nicht eingeloggt';
      notifyListeners();
      return;
    }

    if (!force &&
        _hasLoadedSuccessfully &&
        _loadedGymId == gymId &&
        _activeLoad == null) {
      return;
    }

    _activeLoad ??=
        _performLoad(gymId: gymId, userId: userId).whenComplete(() {
      _activeLoad = null;
    });
    return _activeLoad;
  }

  Future<void> _performLoad({
    required String gymId,
    required String userId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _membership.ensureMembership(gymId, userId);
      List<MuscleGroup> groups;
      try {
        groups = await _getGroups.execute(gymId);
        bool createdCanonical = false;
        for (final region in MuscleRegion.values) {
          final hasCanonical = groups.any(
            (g) => g.region == region && _isCanonicalName(g),
          );
          if (!hasCanonical) {
            await _ensureRegionGroup.execute(gymId, region);
            createdCanonical = true;
          }
        }
        if (createdCanonical) {
          groups = await _getGroups.execute(gymId);
        }
      } on FirebaseException catch (e) {
        if (e.code == 'permission-denied') {
          debugPrint('RULES_DENIED path=gyms/$gymId/muscleGroups op=read');
          await _membership.ensureMembership(gymId, userId);
          debugPrint(
              'RETRY_AFTER_ENSURE_MEMBERSHIP path=gyms/$gymId/muscleGroups op=read');
          groups = await _getGroups.execute(gymId);
        } else {
          rethrow;
        }
      }
      _groups = groups;
      _loadedGymId = gymId;
      _hasLoadedSuccessfully = true;
    } catch (e, st) {
      _error = e.toString();
      debugPrintStack(label: 'MuscleGroupProvider.loadGroups', stackTrace: st);
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = false;
    notifyListeners();

    try {
      await _loadCounts(gymId, userId);
    } catch (e, st) {
      debugPrintStack(
        label: 'MuscleGroupProvider.loadCounts',
        stackTrace: st,
      );
    }
  }

  Future<void> ensureLoaded(BuildContext context, {bool force = false}) {
    return loadGroups(context, force: force);
  }

  Future<void> saveGroup(BuildContext context, MuscleGroup group) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final gymId = auth.gymCode;
    if (gymId == null) return;
    await _safeSaveGroup(gymId, group);

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

    await loadGroups(context, force: true);
  }

  Future<void> deleteGroup(BuildContext context, String groupId) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final gymId = auth.gymCode;
    if (gymId == null) return;
    await _deleteGroup.execute(gymId, groupId);
    await loadGroups(context, force: true);
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
    await loadGroups(ctx, force: true);
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
    final normalized = canonicalizeGroupIds(groupIds);

    for (final g in _groups) {
      if (normalized.contains(g.id) && !g.primaryDeviceIds.contains(deviceId)) {
        final updated = g.copyWith(
          primaryDeviceIds: [...g.primaryDeviceIds, deviceId],
        );
        await _safeSaveGroup(gymId, updated);
      }
    }
    await loadGroups(context, force: true);
  }

  Future<void> assignExercise(
    BuildContext context,
    String exerciseId,
    List<String> groupIds,
  ) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final gymId = auth.gymCode;
    if (gymId == null) return;
    final normalized = canonicalizeGroupIds(groupIds);

    for (final g in _groups) {
      if (normalized.contains(g.id) && !g.exerciseIds.contains(exerciseId)) {
        final updated = g.copyWith(exerciseIds: [...g.exerciseIds, exerciseId]);
        await _safeSaveGroup(gymId, updated);
      }
    }
    await loadGroups(context, force: true);
  }

  Future<void> updateExerciseAssignments(
    BuildContext context,
    String exerciseId,
    List<String> primaryGroupIds,
    List<String> secondaryGroupIds,
  ) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final gymId = auth.gymCode;
    if (gymId == null) return;
    final normalizedPrimary = canonicalizeGroupIds(primaryGroupIds);
    final normalizedSecondary = canonicalizeGroupIds(secondaryGroupIds)
        .where((id) => !normalizedPrimary.contains(id))
        .toList();

    final all = {
      ...normalizedPrimary,
      ...normalizedSecondary,
    };
    for (final g in _groups) {
      final contains = all.contains(g.id);
      if (contains && !g.exerciseIds.contains(exerciseId)) {
        final updated = g.copyWith(exerciseIds: [...g.exerciseIds, exerciseId]);
        await _safeSaveGroup(gymId, updated);
      } else if (!contains && g.exerciseIds.contains(exerciseId)) {
        final newIds = List<String>.from(g.exerciseIds)..remove(exerciseId);
        final updated = g.copyWith(exerciseIds: newIds);
        await _safeSaveGroup(gymId, updated);
      }
    }
    await loadGroups(context, force: true);
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

    final normalizedPrimary = canonicalizeGroupIds(primaryGroupIds);
    final normalizedSecondary = canonicalizeGroupIds(secondaryGroupIds)
        .where((id) => !normalizedPrimary.contains(id))
        .toList();

    for (final g in _groups) {
      final isPrimary = normalizedPrimary.contains(g.id);
      final isSecondary = normalizedSecondary.contains(g.id);

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
      await _safeSaveGroup(gymId, updated);
    }

    await _setDeviceGroups.execute(
      gymId,
      deviceId,
      normalizedPrimary,
      normalizedSecondary,
    );

    try {
      final deviceProv = Provider.of<DeviceProvider>(context, listen: false);
      deviceProv.applyMuscleAssignments(
        deviceId,
        normalizedPrimary,
        normalizedSecondary,
      );
    } catch (_) {}

    await loadGroups(context, force: true);
  }

  Future<void> _safeSaveGroup(String gymId, MuscleGroup group) async {
    try {
      await _saveGroup.execute(gymId, group);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        debugPrint(
          '[MuscleGroupProvider] permission denied saving group ${group.id} in gym $gymId',
        );
      } else {
        rethrow;
      }
    }
  }

  Future<void> _loadCounts(String gymId, String userId) async {
    if (navigatorKey.currentContext == null) return;

    final deviceIds = <String>{
      for (final group in _groups) ...group.deviceIds,
    };
    final deviceCounts = <String, int>{};
    final fetches = deviceIds
        .map((dId) async {
          try {
            final logs = await _getHistory.execute(
              gymId: gymId,
              deviceId: dId,
              userId: userId,
            );
            deviceCounts[dId] = logs.length;
          } catch (e, st) {
            debugPrintStack(
              label: 'MuscleGroupProvider.loadCounts(device=$dId)',
              stackTrace: st,
            );
            deviceCounts[dId] = 0;
          }
        })
        .toList();
    await Future.wait(fetches);

    final nextCounts = <String, int>{};
    for (final group in _groups) {
      final total = group.deviceIds.fold<int>(
        0,
        (acc, dId) => acc + (deviceCounts[dId] ?? 0),
      );
      nextCounts[group.id] = total;
    }

    _counts
      ..clear()
      ..addAll(nextCounts);
    notifyListeners();
  }

  List<String> canonicalizeGroupIds(Iterable<String> ids) {
    final seen = <String>{};
    if (_groups.isEmpty) {
      final List<String> result = [];
      for (final id in ids) {
        if (seen.add(id)) result.add(id);
      }
      return result;
    }

    MuscleGroup? canonicalFor(MuscleRegion region) {
      MuscleGroup? canonical;
      for (final group in _groups.where((g) => g.region == region)) {
        canonical ??= group;
        if (_isCanonicalName(group)) {
          canonical = group;
          break;
        }
      }
      return canonical;
    }

    final Map<String, MuscleGroup> byId = {
      for (final g in _groups) g.id: g,
    };

    final Map<MuscleRegion, String> canonicalIds = {};
    for (final region in MuscleRegion.values) {
      final canonical = canonicalFor(region);
      if (canonical != null) canonicalIds[region] = canonical.id;
    }

    final List<String> normalized = [];
    for (final rawId in ids) {
      final group = byId[rawId];
      if (group == null) continue;
      final canonicalId = canonicalIds[group.region] ?? rawId;
      if (seen.add(canonicalId)) normalized.add(canonicalId);
    }
    return normalized;
  }

  bool _isCanonicalName(MuscleGroup group) {
    return group.name.trim().toLowerCase() == group.region.name.toLowerCase();
  }
}
