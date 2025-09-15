import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../time/logic_day.dart';
import '../utils/duration_format.dart';
import 'workout_timer_telemetry.dart';

enum StopResult { save, discard, cancel }

class WorkoutSessionDurationService extends ChangeNotifier {
  static const _prefsKeyPrefix = 'workoutTimer:';
  static const _queueKey = 'workoutTimerQueue';
  static const Duration _defaultAutoStopDelay = Duration(hours: 1);

  final FirebaseFirestore _firestore;
  final Uuid _uuid = const Uuid();
  final WorkoutTimerTelemetry? _telemetry;
  final Duration _autoStopDelay;
  SharedPreferences? _prefs;

  bool _isRunning = false;
  int? _startEpochMs;
  String? _uid;
  String? _gymId;
  Timer? _ticker;
  final StreamController<Duration> _tickCtrl = StreamController.broadcast();
  Timer? _autoStopTimer;
  String? _firstSessionId;
  String? _lastSessionId;
  int? _lastSessionEpochMs;

  WorkoutSessionDurationService({
    FirebaseFirestore? firestore,
    WorkoutTimerTelemetry? telemetry,
    Duration autoStopDelay = _defaultAutoStopDelay,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _telemetry = telemetry,
        _autoStopDelay = autoStopDelay {
    _init();
  }

  bool get isRunning => _isRunning;
  Stream<Duration> get tickStream => _tickCtrl.stream;
  Duration get elapsed =>
      _startEpochMs != null
          ? Duration(milliseconds:
              DateTime.now().millisecondsSinceEpoch - _startEpochMs!)
          : Duration.zero;

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    // find any running state for current user? We cannot know uid yet
    // but we can scan keys.
    final keys = _prefs!.getKeys().where((k) => k.startsWith(_prefsKeyPrefix));
    if (keys.isNotEmpty) {
      final data = jsonDecode(_prefs!.getString(keys.first)!);
      _startEpochMs = data['startEpochMs'] as int?;
      _uid = data['uid'] as String?;
      _gymId = data['gymId'] as String?;
      _firstSessionId = data['firstSessionId'] as String?;
      _lastSessionId = data['lastSessionId'] as String?;
      final lastMs = data['lastSessionEpochMs'];
      if (lastMs is int) {
        _lastSessionEpochMs = lastMs;
      } else if (lastMs is num) {
        _lastSessionEpochMs = lastMs.toInt();
      }
      if (_startEpochMs != null) {
        _isRunning = true;
        _startTicker();
        _resumeAutoStopTimer();
        notifyListeners();
      }
    }

    await _flushQueue();
  }

  Future<void> start({required String uid, required String gymId}) async {
    if (_isRunning) return;
    _uid = uid;
    _gymId = gymId;
    final now = DateTime.now().millisecondsSinceEpoch;
    _startEpochMs = now;
    _firstSessionId = null;
    _lastSessionId = null;
    _lastSessionEpochMs = null;
    _autoStopTimer?.cancel();
    _isRunning = true;
    await _persistState();
    _startTicker();
    notifyListeners();
    _telemetry?.timerStart();
  }

  Future<void> registerSession({
    required String sessionId,
    required DateTime completedAt,
  }) async {
    if (!_isRunning || _startEpochMs == null) return;
    _firstSessionId ??= sessionId;
    _lastSessionId = sessionId;
    _lastSessionEpochMs = completedAt.millisecondsSinceEpoch;
    await _persistState();
    _scheduleAutoStop();
  }

  /// Prompts the user whether to save or discard the current session.
  ///
  /// Returns [StopResult.save] if the user chooses to persist the duration,
  /// [StopResult.discard] if it should be thrown away, or [StopResult.cancel]
  /// if the dialog was dismissed.
  Future<StopResult> confirmStop(BuildContext context) async {
    if (!_isRunning) return StopResult.cancel;
    final elapsedDur = elapsed;
    final locale = Localizations.localeOf(context);
    final formatted = formatDuration(elapsedDur, locale: locale);
    final result = await showDialog<StopResult>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Training beenden?'),
        content: Text('Dauer: $formatted. Möchtest du die Zeit speichern oder verwerfen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(StopResult.cancel),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(StopResult.discard),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Verwerfen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(StopResult.save),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
    return result ?? StopResult.cancel;
  }

  Future<void> save({DateTime? endTime, String? sessionId}) async {
    if (!_isRunning || _uid == null || _gymId == null || _startEpochMs == null) {
      return;
    }
    final uid = _uid!;
    final gymId = _gymId!;
    final start = DateTime.fromMillisecondsSinceEpoch(_startEpochMs!);
    final end = endTime ?? DateTime.now();
    var durationMs = end.millisecondsSinceEpoch - _startEpochMs!;
    if (durationMs < 0) {
      durationMs = 0;
    }
    final tz = await FlutterTimezone.getLocalTimezone();
    final dayKey = logicDayKey(start);

    var resolvedSessionId = sessionId ?? _firstSessionId;
    var hasSets = resolvedSessionId != null;
    resolvedSessionId ??= _lastSessionId;

    if (!hasSets) {
      try {
        final startDay = DateTime(start.year, start.month, start.day);
        final endDay = startDay.add(const Duration(days: 1));
        final snap = await _firestore
            .collectionGroup('logs')
            .where('userId', isEqualTo: uid)
            .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDay))
            .where('timestamp', isLessThan: Timestamp.fromDate(endDay))
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) {
          resolvedSessionId = snap.docs.first.data()['sessionId'] as String?;
          hasSets = resolvedSessionId != null;
        }
      } catch (_) {
        // ignore lookup failures
      }
    }

    resolvedSessionId ??= _uuid.v4();

    final metaRef = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('users')
        .doc(uid)
        .collection('session_meta')
        .doc(resolvedSessionId);

    final payload = {
      'sessionId': resolvedSessionId,
      'uid': uid,
      'gymId': gymId,
      'startTime': Timestamp.fromDate(start),
      'endTime': Timestamp.fromDate(end),
      'durationMs': durationMs,
      'dayKey': dayKey,
      'tz': tz,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      await metaRef.set(payload, SetOptions(merge: true));
    } on FirebaseException {
      await _enqueuePersist(payload);
    }

    _telemetry?.timerStopSave(
        durationMs: durationMs, dayKey: dayKey, hasSets: hasSets);

    await _clearLocal();
  }

  Future<void> discard() async {
    if (!_isRunning || _startEpochMs == null) return;
    final start = DateTime.fromMillisecondsSinceEpoch(_startEpochMs!);
    final durationMs = DateTime.now().millisecondsSinceEpoch - _startEpochMs!;
    final dayKey = logicDayKey(start);
    _telemetry?.timerStopDiscard(
        durationMs: durationMs, dayKey: dayKey, hasSets: false);
    await _clearLocal();
  }

  Future<void> _clearLocal() async {
    final uid = _uid;
    _isRunning = false;
    _startEpochMs = null;
    _uid = null;
    _gymId = null;
    _firstSessionId = null;
    _lastSessionId = null;
    _lastSessionEpochMs = null;
    _ticker?.cancel();
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
    _tickCtrl.add(Duration.zero);
    notifyListeners();
    if (uid != null) {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.remove('$_prefsKeyPrefix$uid');
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isRunning && _startEpochMs != null) {
        _tickCtrl.add(elapsed);
      }
    });
  }

  Future<void> _persistState() async {
    final uid = _uid;
    if (!_isRunning || uid == null || _startEpochMs == null) return;
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    final data = <String, dynamic>{
      'startEpochMs': _startEpochMs,
      'uid': uid,
      'gymId': _gymId,
      if (_firstSessionId != null) 'firstSessionId': _firstSessionId,
      if (_lastSessionId != null) 'lastSessionId': _lastSessionId,
      if (_lastSessionEpochMs != null) 'lastSessionEpochMs': _lastSessionEpochMs,
    };
    await prefs.setString('$_prefsKeyPrefix$uid', jsonEncode(data));
  }

  void _scheduleAutoStop() {
    if (!_isRunning || _lastSessionEpochMs == null) return;
    _autoStopTimer?.cancel();
    if (_autoStopDelay <= Duration.zero) {
      unawaited(_autoFinalize());
    } else {
      _autoStopTimer = Timer(_autoStopDelay, () {
        unawaited(_autoFinalize());
      });
    }
  }

  void _resumeAutoStopTimer() {
    if (!_isRunning || _lastSessionEpochMs == null) return;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final target = _lastSessionEpochMs! + _autoStopDelay.inMilliseconds;
    final remainingMs = target - nowMs;
    if (remainingMs <= 0) {
      unawaited(_autoFinalize());
    } else {
      _autoStopTimer?.cancel();
      _autoStopTimer = Timer(Duration(milliseconds: remainingMs), () {
        unawaited(_autoFinalize());
      });
    }
  }

  Future<void> _autoFinalize() async {
    if (!_isRunning || _startEpochMs == null || _lastSessionEpochMs == null) {
      return;
    }
    final end = DateTime.fromMillisecondsSinceEpoch(_lastSessionEpochMs!);
    final sid = _firstSessionId ?? _lastSessionId;
    await save(endTime: end, sessionId: sid);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _autoStopTimer?.cancel();
    _tickCtrl.close();
    super.dispose();
  }

  Future<void> _enqueuePersist(Map<String, dynamic> payload) async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    final list = prefs.getStringList(_queueKey) ?? [];
    list.add(jsonEncode(payload));
    await prefs.setStringList(_queueKey, list);
  }

  Future<void> _flushQueue() async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    final list = prefs.getStringList(_queueKey) ?? [];
    if (list.isEmpty) return;

    final remaining = <String>[];
    for (final item in list) {
      try {
        final data = jsonDecode(item) as Map<String, dynamic>;
        final gymId = data['gymId'] as String;
        final uid = data['uid'] as String;
        final sessionId = data['sessionId'] as String;
        final ref = _firestore
            .collection('gyms')
            .doc(gymId)
            .collection('users')
            .doc(uid)
            .collection('session_meta')
            .doc(sessionId);
        await ref.set(data, SetOptions(merge: true));
      } catch (_) {
        remaining.add(item);
      }
    }
    await prefs.setStringList(_queueKey, remaining);
  }
}


