import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import "../../main.dart";
import '../providers/auth_provider.dart';
import '../providers/gym_provider.dart';
import '../../features/muscle_group/data/repositories/muscle_group_repository_impl.dart';
import '../../features/muscle_group/data/sources/firestore_muscle_group_source.dart';
import '../../features/muscle_group/domain/models/muscle_group.dart';
import '../../features/muscle_group/domain/usecases/get_muscle_groups_for_gym.dart';
import '../../features/muscle_group/domain/usecases/save_muscle_group.dart';
import '../../features/history/data/sources/firestore_history_source.dart';
import '../../features/history/data/repositories/history_repository_impl.dart';
import '../../features/history/domain/usecases/get_history_for_device.dart';

class MuscleGroupProvider extends ChangeNotifier {
  final GetMuscleGroupsForGym _getGroups;
  final SaveMuscleGroup _saveGroup;
  final GetHistoryForDevice _getHistory;

  MuscleGroupProvider({
    GetMuscleGroupsForGym? getGroups,
    SaveMuscleGroup? saveGroup,
    GetHistoryForDevice? getHistory,
  })  : _getGroups = getGroups ??
            GetMuscleGroupsForGym(
              MuscleGroupRepositoryImpl(FirestoreMuscleGroupSource()),
            ),
        _saveGroup = saveGroup ??
            SaveMuscleGroup(
              MuscleGroupRepositoryImpl(FirestoreMuscleGroupSource()),
            ),
        _getHistory = getHistory ??
            GetHistoryForDevice(
              HistoryRepositoryImpl(FirestoreHistorySource()),
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
    await loadGroups(context);
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
      if (groupIds.contains(g.id) && !g.deviceIds.contains(deviceId)) {
        final updated = g.copyWith(deviceIds: [...g.deviceIds, deviceId]);
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
