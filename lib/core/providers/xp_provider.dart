import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:tapem/core/logging/elog.dart';
import 'package:tapem/core/logging/xp_trace.dart';
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
      String? exerciseId,
      required String traceId,
    }) async {
      assert(LevelService.xpPerSession == 50);
      XpTrace.log('PROVIDER_IN', {
        'gymId': gymId,
        'uid': userId,
        'deviceId': deviceId,
        'sessionId': sessionId,
        'isMulti': isMulti,
        'exerciseId': exerciseId ?? '',
        'showInLeaderboard': showInLeaderboard,
        'traceId': traceId,
      });
      if (deviceId.isEmpty) {
        XpTrace.log('SKIP', {
          'reason': 'noDevice',
          'traceId': traceId,
        });
        return DeviceXpResult.skipNoDevice;
      }
      try {
        final result = await _repo.addSessionXp(
          gymId: gymId,
          userId: userId,
          deviceId: deviceId,
          sessionId: sessionId,
          showInLeaderboard: showInLeaderboard,
          isMulti: isMulti,
          exerciseId: exerciseId,
          traceId: traceId,
        );
        XpTrace.log('PROVIDER_OUT', {
          'result': result.name,
          'deltaXp': result == DeviceXpResult.okAdded ? 50 : 0,
          'updatedLocalCache': result == DeviceXpResult.okAdded,
          'traceId': traceId,
        });
        if (result == DeviceXpResult.okAdded) {
          _deviceXp[deviceId] =
              (_deviceXp[deviceId] ?? 0) + LevelService.xpPerSession;
          XpTrace.log('CACHE_BUMP', {
            'deviceId': deviceId,
            'newXp': _deviceXp[deviceId],
            'traceId': traceId,
          });
          notifyListeners();
        }
        return result;
      } catch (e, st) {
        XpTrace.log('PROVIDER_OUT', {
          'result': 'error',
          'err': e.toString(),
          'traceId': traceId,
        });
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
    XpTrace.log('WATCH_INIT', {
      'deviceCountBeforeAttach': _deviceSubs.length,
      'gymId': gymId,
      'uid': userId,
    });
    final detached = <String>[];
    for (final id in _deviceSubs.keys.toList()) {
      if (!deviceIds.contains(id)) {
        _deviceSubs[id]?.cancel();
        _deviceSubs.remove(id);
        _deviceXp.remove(id);
        detached.add(id);
      }
    }
    final attached = <String>[];
    for (final id in deviceIds) {
      if (_deviceSubs.containsKey(id)) continue;
      attached.add(id);
      _deviceSubs[id] = _repo
          .watchDeviceXp(gymId: gymId, deviceId: id, userId: userId)
          .listen((xp) {
            _deviceXp[id] = xp;
            final level = xp ~/ LevelService.xpPerLevel + 1;
            XpTrace.log('WATCH_UPDATE', {
              'deviceId': id,
              'xp': xp,
              'level': level,
            });
            notifyListeners();
          });
    }
    if (attached.isNotEmpty || detached.isNotEmpty) {
      XpTrace.log('WATCH_ATTACH', {
        'attached': attached,
        'detached': detached,
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
