import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:tapem/features/xp/domain/xp_repository.dart';
import 'package:tapem/features/xp/data/sources/firestore_xp_source.dart';
import 'package:tapem/features/xp/data/repositories/xp_repository_impl.dart';

class XpProvider extends ChangeNotifier {
  final XpRepository _repo;
  XpProvider({XpRepository? repo})
    : _repo = repo ?? XpRepositoryImpl(FirestoreXpSource());

  Map<String, int> _muscleXp = {};
  int _dayXp = 0;
  StreamSubscription<int>? _daySub;
  StreamSubscription<Map<String, int>>? _muscleSub;
  Map<String, int> _dayListXp = {};
  final Map<String, int> _deviceXp = {};
  StreamSubscription<Map<String, int>>? _dayListSub;
  final Map<String, StreamSubscription<int>> _deviceSubs = {};

  Map<String, int> get muscleXp => _muscleXp;
  int get dayXp => _dayXp;
  Map<String, int> get dayListXp => _dayListXp;
  Map<String, int> get deviceXp => _deviceXp;

  Future<void> addSessionXp({
    required String gymId,
    required String userId,
    required String deviceId,
    required String sessionId,
    required bool showInLeaderboard,
    required bool isMulti,
    required List<String> primaryMuscleGroupIds,
  }) {
    return _repo.addSessionXp(
      gymId: gymId,
      userId: userId,
      deviceId: deviceId,
      sessionId: sessionId,
      showInLeaderboard: showInLeaderboard,
      isMulti: isMulti,
      primaryMuscleGroupIds: primaryMuscleGroupIds,
    );
  }

  void watchDayXp(String userId, DateTime date) {
    _daySub?.cancel();
    _daySub = _repo.watchDayXp(userId: userId, date: date).listen((value) {
      _dayXp = value;
      notifyListeners();
    });
  }

  void watchMuscleXp(String userId) {
    _muscleSub?.cancel();
    _muscleSub = _repo.watchMuscleXp(userId).listen((map) {
      _muscleXp = map;
      notifyListeners();
    });
  }

  void watchTrainingDays(String userId) {
    _dayListSub?.cancel();
    _dayListSub = _repo.watchTrainingDaysXp(userId).listen((map) {
      _dayListXp = map;
      notifyListeners();
    });
  }

  void watchDeviceXp(String gymId, String userId, List<String> deviceIds) {
    for (final id in _deviceSubs.keys.toList()) {
      if (!deviceIds.contains(id)) {
        _deviceSubs[id]?.cancel();
        _deviceSubs.remove(id);
        _deviceXp.remove(id);
      }
    }
    for (final id in deviceIds) {
      if (_deviceSubs.containsKey(id)) continue;
      _deviceSubs[id] = _repo
          .watchDeviceXp(gymId: gymId, deviceId: id, userId: userId)
          .listen((xp) {
            _deviceXp[id] = xp;
            notifyListeners();
          });
    }
  }

  @override
  void dispose() {
    _daySub?.cancel();
    _muscleSub?.cancel();
    _dayListSub?.cancel();
    for (final sub in _deviceSubs.values) {
      sub.cancel();
    }
    super.dispose();
  }
}
