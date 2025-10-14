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
  DateTime? _dayWatchDate;
  String? _dayWatchUserId;
  DateTime? _lastDayFetch;
  bool _loadingDay = false;

  Map<String, Map<String, int>> _muscleDailyXp = {};
  String? _muscleHistoryGymId;
  String? _muscleHistoryUserId;
  DateTime? _lastMuscleHistoryFetch;
  bool _loadingMuscleHistory = false;

  String? _muscleGymId;
  String? _muscleUserId;
  DateTime? _lastMuscleFetch;
  bool _loadingMuscle = false;

  Map<String, int> _dayListXp = {};
  String? _trainingDaysUserId;
  DateTime? _lastTrainingDaysFetch;
  bool _loadingTrainingDays = false;

  final Map<String, int> _deviceXp = {};
  final Map<String, DateTime> _deviceLastFetch = {};
  final Set<String> _deviceLoading = {};
  List<String> _deviceIds = const [];
  String? _deviceGymId;
  String? _deviceUserId;

  int _statsDailyXp = 0;
  int _dailyLevel = 1;
  int _dailyLevelXp = 0;
  String? _statsDailyGymId;
  String? _statsDailyUserId;
  DateTime? _lastStatsFetch;
  bool _loadingStats = false;

  Timer? _pollTimer;
  final Duration _pollInterval = const Duration(minutes: 2);
  final Duration _cacheTtl = const Duration(minutes: 2);

  Map<String, int> get muscleXp => _muscleXp;
  int get dayXp => _dayXp;
  Map<String, int> get dayListXp => _dayListXp;
  Map<String, int> get deviceXp => _deviceXp;
  int get statsDailyXp => _statsDailyXp;
  int get dailyLevel => _dailyLevel;
  int get dailyLevelXp => _dailyLevelXp;
  Map<String, Map<String, int>> get muscleDailyXp => _muscleDailyXp;
  double get dailyProgress =>
      _dailyLevel >= LevelService.maxLevel
          ? 1
          : _dailyLevelXp / LevelService.xpPerLevel;

  bool _isFresh(DateTime? timestamp) {
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheTtl;
  }

  bool get _hasActiveWatch =>
      _dayWatchUserId != null ||
      _muscleUserId != null ||
      _muscleHistoryUserId != null ||
      _trainingDaysUserId != null ||
      _statsDailyUserId != null ||
      _deviceIds.isNotEmpty;

  void _ensurePolling() {
    if (_hasActiveWatch && _pollTimer == null) {
      _pollTimer = Timer.periodic(_pollInterval, (_) {
        unawaited(_poll());
      });
    } else if (!_hasActiveWatch) {
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  Future<void> _poll() async {
    await _loadDayXp();
    await _loadMuscleXp();
    await _loadMuscleHistory();
    await _loadTrainingDays();
    await _loadStatsDailyXp();
    await _loadAllDeviceXp();
  }

  Future<DeviceXpResult> addSessionXp({
      required String gymId,
      required String userId,
      required String deviceId,
      required String sessionId,
      required bool showInLeaderboard,
      required bool isMulti,
      String? exerciseId,
      required String traceId,
      List<String> primaryMuscleGroupIds = const [],
      List<String> secondaryMuscleGroupIds = const [],
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
          primaryMuscleGroupIds: primaryMuscleGroupIds,
          secondaryMuscleGroupIds: secondaryMuscleGroupIds,
        );
        XpTrace.log('PROVIDER_OUT', {
          'result': result.name,
          'deltaXp':
              result == DeviceXpResult.okAdded ||
                      result == DeviceXpResult.okAddedNoLeaderboard
                  ? 50
                  : 0,
          'updatedLocalCache': result == DeviceXpResult.okAdded ||
              result == DeviceXpResult.okAddedNoLeaderboard,
          'traceId': traceId,
        });
        if (result == DeviceXpResult.okAdded ||
            result == DeviceXpResult.okAddedNoLeaderboard) {
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
    if (userId.isEmpty) {
      _dayWatchUserId = null;
      _dayWatchDate = null;
      _dayXp = 0;
      _ensurePolling();
      notifyListeners();
      return;
    }
    _dayWatchUserId = userId;
    _dayWatchDate = DateTime(date.year, date.month, date.day);
    _ensurePolling();
    unawaited(_loadDayXp(force: true));
  }

  void watchMuscleXp(String gymId, String userId) {
    debugPrint('👀 provider watchMuscleXp userId=$userId gymId=$gymId');
    if (gymId.isEmpty || userId.isEmpty) {
      _muscleGymId = null;
      _muscleUserId = null;
      _muscleXp = {};
      _ensurePolling();
      notifyListeners();
      return;
    }
    _muscleGymId = gymId;
    _muscleUserId = userId;
    _ensurePolling();
    unawaited(_loadMuscleXp(force: true));
  }

  void watchMuscleDailyXp(String gymId, String userId) {
    debugPrint('👀 provider watchMuscleDailyXp userId=$userId gymId=$gymId');
    if (gymId.isEmpty || userId.isEmpty) {
      _muscleHistoryGymId = null;
      _muscleHistoryUserId = null;
      _muscleDailyXp = {};
      _ensurePolling();
      notifyListeners();
      return;
    }
    _muscleHistoryGymId = gymId;
    _muscleHistoryUserId = userId;
    _ensurePolling();
    unawaited(_loadMuscleHistory(force: true));
  }

  void watchTrainingDays(String userId) {
    if (userId.isEmpty) {
      debugPrint('⚠️ provider watchTrainingDays skipped (empty userId)');
      _trainingDaysUserId = null;
      _dayListXp = {};
      _ensurePolling();
      notifyListeners();
      return;
    }
    if (_trainingDaysUserId == userId && _isFresh(_lastTrainingDaysFetch)) {
      debugPrint('🔁 provider watchTrainingDays reuse userId=$userId');
      return;
    }
    debugPrint('👀 provider watchTrainingDays userId=$userId');
    _trainingDaysUserId = userId;
    _ensurePolling();
    unawaited(_loadTrainingDays(force: true));
  }

  void watchDeviceXp(String gymId, String userId, List<String> deviceIds) {
    XpTrace.log('WATCH_INIT', {
      'gymId': gymId,
      'uid': userId,
      'requestedDevices': deviceIds.length,
    });

    final normalized = deviceIds.toSet().toList()..sort();

    if (gymId.isEmpty || userId.isEmpty || normalized.isEmpty) {
      for (final id in _deviceXp.keys.toList()) {
        if (!normalized.contains(id)) {
          _deviceXp.remove(id);
          _deviceLastFetch.remove(id);
          _deviceLoading.remove(id);
        }
      }
      _deviceIds = const [];
      _deviceGymId = null;
      _deviceUserId = null;
      _ensurePolling();
      notifyListeners();
      return;
    }

    final removed = _deviceIds.where((id) => !normalized.contains(id)).toList();
    for (final id in removed) {
      _deviceXp.remove(id);
      _deviceLastFetch.remove(id);
      _deviceLoading.remove(id);
    }

    _deviceIds = normalized;
    _deviceGymId = gymId;
    _deviceUserId = userId;
    _ensurePolling();

    for (final id in _deviceIds) {
      unawaited(_loadDeviceXp(id, force: true));
    }
    notifyListeners();
  }

  void watchStatsDailyXp(String gymId, String userId) {
    if (gymId.isEmpty || userId.isEmpty) {
      debugPrint(
          '⚠️ provider watchStatsDailyXp skipped (gymId="$gymId" userId="$userId")');
      _statsDailyGymId = null;
      _statsDailyUserId = null;
      _statsDailyXp = 0;
      _dailyLevel = 1;
      _dailyLevelXp = 0;
      _ensurePolling();
      notifyListeners();
      return;
    }
    if (_statsDailyGymId == gymId &&
        _statsDailyUserId == userId &&
        _isFresh(_lastStatsFetch)) {
      debugPrint(
          '🔁 provider watchStatsDailyXp reuse gymId=$gymId userId=$userId');
      return;
    }
    debugPrint('👀 provider watchStatsDailyXp gymId=$gymId userId=$userId');
    _statsDailyGymId = gymId;
    _statsDailyUserId = userId;
    _ensurePolling();
    unawaited(_loadStatsDailyXp(force: true));
  }

  Future<void> refreshAll({bool includeDevices = true}) async {
    await _loadDayXp(force: true);
    await _loadMuscleXp(force: true);
    await _loadMuscleHistory(force: true);
    await _loadTrainingDays(force: true);
    await _loadStatsDailyXp(force: true);
    if (includeDevices) {
      await _loadAllDeviceXp(force: true);
    }
  }

  Future<void> _loadDayXp({bool force = false}) async {
    if (_dayWatchUserId == null || _dayWatchDate == null) {
      return;
    }
    if (_loadingDay || (!force && _isFresh(_lastDayFetch))) {
      return;
    }
    _loadingDay = true;
    try {
      final xp = await _repo.fetchDayXp(
        userId: _dayWatchUserId!,
        date: _dayWatchDate!,
      );
      _lastDayFetch = DateTime.now();
      if (_dayXp != xp) {
        _dayXp = xp;
        notifyListeners();
      }
    } catch (e, st) {
      elogError('XP_FETCH_DAY', e, st, {
        'uid': _dayWatchUserId,
      });
    } finally {
      _loadingDay = false;
    }
  }

  Future<void> _loadMuscleXp({bool force = false}) async {
    if (_muscleGymId == null || _muscleUserId == null) {
      return;
    }
    if (_loadingMuscle || (!force && _isFresh(_lastMuscleFetch))) {
      return;
    }
    _loadingMuscle = true;
    try {
      final map = await _repo.fetchMuscleXp(
        gymId: _muscleGymId!,
        userId: _muscleUserId!,
      );
      _lastMuscleFetch = DateTime.now();
      if (!mapEquals(_muscleXp, map)) {
        _muscleXp = map;
        notifyListeners();
      }
    } catch (e, st) {
      elogError('XP_FETCH_MUSCLE', e, st, {
        'uid': _muscleUserId,
        'gymId': _muscleGymId,
      });
    } finally {
      _loadingMuscle = false;
    }
  }

  Future<void> _loadMuscleHistory({bool force = false}) async {
    if (_muscleHistoryGymId == null || _muscleHistoryUserId == null) {
      return;
    }
    if (_loadingMuscleHistory ||
        (!force && _isFresh(_lastMuscleHistoryFetch))) {
      return;
    }
    _loadingMuscleHistory = true;
    try {
      final map = await _repo.fetchMuscleXpHistory(
        gymId: _muscleHistoryGymId!,
        userId: _muscleHistoryUserId!,
        limit: 30,
      );
      _lastMuscleHistoryFetch = DateTime.now();
      if (!mapEquals(_muscleDailyXp, map)) {
        _muscleDailyXp = map;
        notifyListeners();
      }
    } catch (e, st) {
      elogError('XP_FETCH_MUSCLE_HISTORY', e, st, {
        'uid': _muscleHistoryUserId,
        'gymId': _muscleHistoryGymId,
      });
    } finally {
      _loadingMuscleHistory = false;
    }
  }

  Future<void> _loadTrainingDays({bool force = false}) async {
    final uid = _trainingDaysUserId;
    if (uid == null) {
      return;
    }
    if (_loadingTrainingDays || (!force && _isFresh(_lastTrainingDaysFetch))) {
      return;
    }
    _loadingTrainingDays = true;
    try {
      final map = await _repo.fetchTrainingDaysXp(uid, limit: 30);
      _lastTrainingDaysFetch = DateTime.now();
      if (!mapEquals(_dayListXp, map)) {
        _dayListXp = map;
        notifyListeners();
      }
    } catch (e, st) {
      elogError('XP_FETCH_TRAINING_DAYS', e, st, {
        'uid': uid,
      });
    } finally {
      _loadingTrainingDays = false;
    }
  }

  Future<void> _loadStatsDailyXp({bool force = false}) async {
    if (_statsDailyGymId == null || _statsDailyUserId == null) {
      return;
    }
    if (_loadingStats || (!force && _isFresh(_lastStatsFetch))) {
      return;
    }
    _loadingStats = true;
    try {
      final xp = await _repo.fetchStatsDailyXp(
        gymId: _statsDailyGymId!,
        userId: _statsDailyUserId!,
      );
      _lastStatsFetch = DateTime.now();
      if (_statsDailyXp != xp) {
        _statsDailyXp = xp;
        var level = (xp ~/ LevelService.xpPerLevel) + 1;
        if (level > LevelService.maxLevel) {
          level = LevelService.maxLevel;
        }
        final xpInLevel =
            level >= LevelService.maxLevel ? 0 : xp % LevelService.xpPerLevel;
        _dailyLevel = level;
        _dailyLevelXp = xpInLevel;
        notifyListeners();
      }
    } catch (e, st) {
      elogError('XP_FETCH_STATS_DAILY', e, st, {
        'uid': _statsDailyUserId,
        'gymId': _statsDailyGymId,
      });
    } finally {
      _loadingStats = false;
    }
  }

  Future<void> _loadAllDeviceXp({bool force = false}) async {
    if (_deviceGymId == null || _deviceUserId == null || _deviceIds.isEmpty) {
      return;
    }
    for (final id in _deviceIds) {
      await _loadDeviceXp(id, force: force);
    }
  }

  Future<void> _loadDeviceXp(String deviceId, {bool force = false}) async {
    if (_deviceGymId == null || _deviceUserId == null) {
      return;
    }
    if (_deviceLoading.contains(deviceId)) {
      return;
    }
    if (!force && _isFresh(_deviceLastFetch[deviceId])) {
      return;
    }
    _deviceLoading.add(deviceId);
    try {
      final xp = await _repo.fetchDeviceXp(
        gymId: _deviceGymId!,
        deviceId: deviceId,
        userId: _deviceUserId!,
      );
      _deviceLastFetch[deviceId] = DateTime.now();
      final previous = _deviceXp[deviceId];
      if (previous != xp) {
        _deviceXp[deviceId] = xp;
        final level = xp ~/ LevelService.xpPerLevel + 1;
        XpTrace.log('WATCH_UPDATE', {
          'deviceId': deviceId,
          'xp': xp,
          'level': level,
        });
        notifyListeners();
      }
    } catch (e, st) {
      elogError('XP_FETCH_DEVICE', e, st, {
        'deviceId': deviceId,
        'gymId': _deviceGymId,
        'uid': _deviceUserId,
      });
    } finally {
      _deviceLoading.remove(deviceId);
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _deviceLoading.clear();
    super.dispose();
  }
}
