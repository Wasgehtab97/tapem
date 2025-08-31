import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:tapem/core/logging/elog.dart';
import 'package:tapem/core/time/logic_day.dart';
import 'package:tapem/features/xp/domain/device_xp_result.dart';
import 'package:tapem/features/xp/domain/xp_repository.dart';
import 'package:tapem/features/xp/data/sources/firestore_xp_source.dart';
import 'package:tapem/features/xp/data/repositories/xp_repository_impl.dart';
import 'package:tapem/features/rank/domain/services/level_service.dart';

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
  int _statsDailyXp = 0;
  StreamSubscription<int>? _statsDailySub;

  Map<String, int> get muscleXp => _muscleXp;
  int get dayXp => _dayXp;
  Map<String, int> get dayListXp => _dayListXp;
  Map<String, int> get deviceXp => _deviceXp;
  int get statsDailyXp => _statsDailyXp;

    Future<DeviceXpResult> addSessionXp({
      required String gymId,
      required String userId,
      required String deviceId,
      required String sessionId,
      required bool showInLeaderboard,
      required bool isMulti,
    }) async {
      assert(LevelService.xpPerSession == 50);
      if (deviceId.isEmpty) {
        elogDeviceXp('SKIP_NO_DEVICE', {
          'uid': userId,
          'gymId': gymId,
          'sessionId': sessionId,
          'deviceId': deviceId,
          'isMulti': isMulti,
        });
        return DeviceXpResult.skipNoDevice;
      }
      if (!showInLeaderboard) {
        elogDeviceXp('LEADERBOARD_FLAG_INFO', {
          'uid': userId,
          'gymId': gymId,
          'deviceId': deviceId,
          'sessionId': sessionId,
        });
      }
      final dayKey = logicDayKey(DateTime.now().toUtc());
      elogDeviceXp('XP_ADD_REQUEST', {
        'uid': userId,
        'gymId': gymId,
        'deviceId': deviceId,
        'sessionId': sessionId,
        'isMulti': isMulti,
        'dayKey': dayKey,
        'showInLeaderboard': showInLeaderboard,
      });
      try {
        final result = await _repo.addSessionXp(
          gymId: gymId,
          userId: userId,
          deviceId: deviceId,
          sessionId: sessionId,
          showInLeaderboard: showInLeaderboard,
          isMulti: isMulti,
        );
        elogDeviceXp('XP_ADD_RESPONSE', {
          'result': result.name,
          'deviceId': deviceId,
          'sessionId': sessionId,
        });
        if (result == DeviceXpResult.okAdded) {
          _deviceXp[deviceId] =
              (_deviceXp[deviceId] ?? 0) + LevelService.xpPerSession;
          notifyListeners();
        }
        return result;
      } catch (e, st) {
        elogError('XP_ADD_UNEXPECTED', e, st, {
          'uid': userId,
          'gymId': gymId,
          'deviceId': deviceId,
          'sessionId': sessionId,
        });
        return DeviceXpResult.error;
      }
    }

  void watchDayXp(String userId, DateTime date) {
    debugPrint('👀 provider watchDayXp userId=$userId date=$date');
    _daySub?.cancel();
    _daySub = _repo.watchDayXp(userId: userId, date: date).listen((value) {
      _dayXp = value;
      debugPrint('🔄 provider dayXp=$value');
      notifyListeners();
    });
  }

  void watchMuscleXp(String gymId, String userId) {
    debugPrint('👀 provider watchMuscleXp userId=$userId gymId=$gymId');
    _muscleSub?.cancel();
    _muscleSub = _repo.watchMuscleXp(gymId: gymId, userId: userId).listen((
      map,
    ) {
      _muscleXp = map;
      debugPrint('🔄 provider muscleXp=${map.length} entries $map');
      notifyListeners();
    });
  }

  void watchTrainingDays(String userId) {
    debugPrint('👀 provider watchTrainingDays userId=$userId');
    _dayListSub?.cancel();
    _dayListSub = _repo.watchTrainingDaysXp(userId).listen((map) {
      _dayListXp = map;
      debugPrint('🔄 provider dayListXp=${map.length} days');
      notifyListeners();
    });
  }

  void watchDeviceXp(String gymId, String userId, List<String> deviceIds) {
    debugPrint('👀 provider watchDeviceXp userId=$userId devices=$deviceIds');
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
            debugPrint('🔄 provider device $id xp=$xp');
            notifyListeners();
          });
    }
  }

  void watchStatsDailyXp(String gymId, String userId) {
    debugPrint('👀 provider watchStatsDailyXp gymId=$gymId userId=$userId');
    _statsDailySub?.cancel();
    _statsDailySub = _repo
        .watchStatsDailyXp(gymId: gymId, userId: userId)
        .listen((xp) {
          _statsDailyXp = xp;
          debugPrint('🔄 provider statsDailyXp=$xp');
          notifyListeners();
        });
  }

  @override
  void dispose() {
    _daySub?.cancel();
    _muscleSub?.cancel();
    _dayListSub?.cancel();
    _statsDailySub?.cancel();
    for (final sub in _deviceSubs.values) {
      sub.cancel();
    }
    super.dispose();
  }
}
