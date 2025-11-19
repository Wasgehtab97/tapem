import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:tapem/l10n/app_localizations.dart';

import '../providers/auth_providers.dart';
import '../providers/firebase_provider.dart';
import '../time/logic_day.dart';
import '../utils/duration_format.dart';
import 'workout_timer_telemetry.dart';

enum StopResult { discard, cancel }

class WorkoutSessionCompletionEvent {
  final String gymId;
  final String userId;
  final String dayKey;
  final DateTime start;
  final DateTime end;
  final String? sessionId;
  final int durationMs;

  const WorkoutSessionCompletionEvent({
    required this.gymId,
    required this.userId,
    required this.dayKey,
    required this.start,
    required this.end,
    required this.durationMs,
    this.sessionId,
  });
}

class StopDialogResult {
  final StopResult result;
  final String? sessionKey;

  const StopDialogResult(
    this.result, {
    this.sessionKey,
  });
}

class WorkoutSessionDurationService extends ChangeNotifier {
  static const _prefsKeyPrefix = 'workoutTimer:';
  static const _prefsKeyDelimiter = '::';
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
  String? _activePrefsKey;
  Timer? _ticker;
  final StreamController<Duration> _tickCtrl = StreamController.broadcast();
  Timer? _autoStopTimer;
  String? _firstSessionId;
  String? _lastSessionId;
  int? _lastActivityEpochMs;
  final StreamController<WorkoutSessionCompletionEvent> _completionCtrl =
      StreamController<WorkoutSessionCompletionEvent>.broadcast();

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
  Stream<WorkoutSessionCompletionEvent> get completionStream =>
      _completionCtrl.stream;
  Duration get elapsed {
    if (_startEpochMs == null) {
      return Duration.zero;
    }
    final referenceMs =
        _ticker == null && _lastActivityEpochMs != null
            ? _lastActivityEpochMs!
            : DateTime.now().millisecondsSinceEpoch;
    var diff = referenceMs - _startEpochMs!;
    if (diff < 0) {
      diff = 0;
    }
    return Duration(milliseconds: diff);
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    await _migrateLegacyKeys();
    await _flushQueue();
  }

  Future<void> setActiveContext({String? uid, String? gymId}) async {
    await _ensurePrefs();
    final prefs = _prefs!;
    final newKey =
        (uid != null && gymId != null) ? _prefsKeyFor(uid, gymId) : null;

    if (_activePrefsKey == newKey && _uid == uid && _gymId == gymId) {
      return;
    }

    final wasRunning = _isRunning;

    _stopTicker();
    _autoStopTimer?.cancel();
    _autoStopTimer = null;

    _uid = uid;
    _gymId = gymId;
    _activePrefsKey = newKey;
    _firstSessionId = null;
    _lastSessionId = null;
    _lastActivityEpochMs = null;
    _startEpochMs = null;
    var shouldNotify = false;

    if (newKey != null) {
      final raw = prefs.getString(newKey) ?? await _readLegacy(uid!);
      if (raw != null) {
        try {
          final data = jsonDecode(raw) as Map<String, dynamic>;
          _startEpochMs = data['startEpochMs'] as int?;
          _firstSessionId = data['firstSessionId'] as String?;
          _lastSessionId = data['lastSessionId'] as String?;
          final lastMs =
              data['lastActivityEpochMs'] ?? data['lastSessionEpochMs'];
          if (lastMs is int) {
            _lastActivityEpochMs = lastMs;
          } else if (lastMs is num) {
            _lastActivityEpochMs = lastMs.toInt();
          }
        } catch (_) {
          // ignore malformed persisted state
        }

        if (_startEpochMs != null) {
          _isRunning = true;
          _startTicker();
          _resumeAutoStopTimer();
          shouldNotify = true;
          _tickCtrl.add(elapsed);
          notifyListeners();
          return;
        }

        _isRunning = false;
        shouldNotify = true;
        _tickCtrl.add(Duration.zero);
        notifyListeners();
        return;
      }
    }

    if (wasRunning || _startEpochMs != null) {
      shouldNotify = true;
    }
    _isRunning = false;
    _tickCtrl.add(Duration.zero);
    if (shouldNotify) {
      notifyListeners();
    }
  }

  Future<void> start({required String uid, required String gymId}) async {
    if (_isRunning) return;
    _uid = uid;
    _gymId = gymId;
    _activePrefsKey = _prefsKeyFor(uid, gymId);
    final now = DateTime.now().millisecondsSinceEpoch;
    _startEpochMs = now;
    _firstSessionId = null;
    _lastSessionId = null;
    _lastActivityEpochMs = null;
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
    _lastActivityEpochMs = completedAt.millisecondsSinceEpoch;
    await _persistState();
    _ensureTickerRunning();
    _scheduleAutoStop();
  }

  Future<void> registerSetCompletion({
    required DateTime completedAt,
  }) async {
    if (!_isRunning || _startEpochMs == null) return;
    _lastActivityEpochMs = completedAt.millisecondsSinceEpoch;
    await _persistState();
    _ensureTickerRunning();
    _scheduleAutoStop();
  }

  /// Prompts the user whether to discard the current session or keep it
  /// running.
  ///
  /// Returns [StopResult.discard] if the user chooses to throw away the
  /// duration, and [StopResult.cancel] if the dialog was dismissed.
  Future<StopDialogResult> confirmStop(
    BuildContext context, {
    String? sessionKey,
  }) async {
    if (!_isRunning) {
      return StopDialogResult(
        StopResult.cancel,
        sessionKey: sessionKey,
      );
    }
    final elapsedDur = elapsed;
    final locale = Localizations.localeOf(context);
    final formatted = formatDuration(elapsedDur, locale: locale);
    final loc = AppLocalizations.of(context)!;
    final result = await showDialog<StopDialogResult>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.sessionStopTitle),
        content: Text(loc.sessionStopMessage(formatted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(
              StopDialogResult(
                StopResult.cancel,
                sessionKey: sessionKey,
              ),
            ),
            child: Text(loc.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(
              StopDialogResult(
                StopResult.discard,
                sessionKey: sessionKey,
              ),
            ),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(loc.commonDiscard),
          ),
        ],
      ),
    );
    return result ??
        StopDialogResult(
          StopResult.cancel,
          sessionKey: sessionKey,
        );
  }

  Future<void> save({DateTime? endTime, String? sessionId}) async {
    if (!_isRunning || _uid == null || _gymId == null || _startEpochMs == null) {
      return;
    }
    final uid = _uid!;
    final gymId = _gymId!;
    final start = DateTime.fromMillisecondsSinceEpoch(_startEpochMs!);
    final end = endTime ??
        (_lastActivityEpochMs != null
            ? DateTime.fromMillisecondsSinceEpoch(_lastActivityEpochMs!)
            : DateTime.now());
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

    final completionEvent = WorkoutSessionCompletionEvent(
      gymId: gymId,
      userId: uid,
      dayKey: dayKey,
      start: start,
      end: end,
      durationMs: durationMs,
      sessionId: resolvedSessionId,
    );

    await _clearLocal();
    _completionCtrl.add(completionEvent);
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

  Future<void> _clearLocal({bool removePersisted = true}) async {
    final uid = _uid;
    final gymId = _gymId;
    _isRunning = false;
    _startEpochMs = null;
    _uid = null;
    _gymId = null;
    _activePrefsKey = null;
    _firstSessionId = null;
    _lastSessionId = null;
    _lastActivityEpochMs = null;
    _ticker?.cancel();
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
    _tickCtrl.add(Duration.zero);
    notifyListeners();
    if (removePersisted && uid != null) {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      if (gymId != null) {
        await prefs.remove(_prefsKeyFor(uid, gymId));
      }
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

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _ensureTickerRunning() {
    if (!_isRunning) return;
    if (_ticker != null && (_ticker?.isActive ?? false)) {
      return;
    }
    _startTicker();
  }

  Future<void> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  String _prefsKeyFor(String uid, String gymId) =>
      '$_prefsKeyPrefix$uid$_prefsKeyDelimiter$gymId';

  Future<String?> _readLegacy(String uid) async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    return prefs.getString('$_prefsKeyPrefix$uid');
  }

  Future<void> _persistState() async {
    final uid = _uid;
    final gymId = _gymId;
    if (!_isRunning || uid == null || gymId == null || _startEpochMs == null) {
      return;
    }
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    final data = <String, dynamic>{
      'startEpochMs': _startEpochMs,
      'uid': uid,
      'gymId': gymId,
      if (_firstSessionId != null) 'firstSessionId': _firstSessionId,
      if (_lastSessionId != null) 'lastSessionId': _lastSessionId,
      if (_lastActivityEpochMs != null) ...{
        'lastActivityEpochMs': _lastActivityEpochMs,
        'lastSessionEpochMs': _lastActivityEpochMs,
      },
    };
    await prefs.setString(_prefsKeyFor(uid, gymId), jsonEncode(data));
    await prefs.remove('$_prefsKeyPrefix$uid');
  }

  void _scheduleAutoStop() {
    if (!_isRunning || _lastActivityEpochMs == null) return;
    _autoStopTimer?.cancel();
    if (_autoStopDelay <= Duration.zero) {
      _handleAutoStopTimeout();
    } else {
      _autoStopTimer = Timer(_autoStopDelay, _handleAutoStopTimeout);
    }
  }

  void _resumeAutoStopTimer() {
    if (!_isRunning || _lastActivityEpochMs == null) return;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final target = _lastActivityEpochMs! + _autoStopDelay.inMilliseconds;
    final remainingMs = target - nowMs;
    if (remainingMs <= 0) {
      _handleAutoStopTimeout();
    } else {
      _autoStopTimer?.cancel();
      _autoStopTimer =
          Timer(Duration(milliseconds: remainingMs), _handleAutoStopTimeout);
    }
  }

  void _handleAutoStopTimeout() {
    if (!_isRunning || _startEpochMs == null || _lastActivityEpochMs == null) {
      return;
    }
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
    _stopTicker();
    _tickCtrl.add(elapsed);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _autoStopTimer?.cancel();
    _tickCtrl.close();
    _completionCtrl.close();
    super.dispose();
  }

  Future<void> _migrateLegacyKeys() async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefsKeyPrefix));
    for (final key in keys) {
      if (key.contains(_prefsKeyDelimiter)) continue;
      final raw = prefs.getString(key);
      if (raw == null) continue;
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final uid = data['uid'] as String?;
        final gymId = data['gymId'] as String?;
        if (uid == null || gymId == null) continue;
        final newKey = _prefsKeyFor(uid, gymId);
        await prefs.setString(newKey, raw);
        await prefs.remove(key);
      } catch (_) {
        // ignore malformed legacy values
      }
    }
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

final workoutSessionDurationServiceProvider =
    ChangeNotifierProvider<WorkoutSessionDurationService>((ref) {
  final service = WorkoutSessionDurationService(
    firestore: ref.watch(firebaseFirestoreProvider),
  );

  Future<void> update(AuthViewState state) {
    return service.setActiveContext(
      uid: state.userId,
      gymId: state.gymCode,
    );
  }

  unawaited(update(ref.read(authViewStateProvider)));

  ref.listen<AuthViewState>(
    authViewStateProvider,
    (_, next) => unawaited(update(next)),
    fireImmediately: false,
  );

  ref.onDispose(service.dispose);
  return service;
});


