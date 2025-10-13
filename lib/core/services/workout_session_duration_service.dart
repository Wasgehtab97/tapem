import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:tapem/l10n/app_localizations.dart';

import '../drafts/session_draft.dart';
import '../drafts/session_draft_repository.dart';
import '../drafts/session_draft_repository_impl.dart';

import '../time/logic_day.dart';
import '../utils/duration_format.dart';
import 'workout_timer_telemetry.dart';

enum StopResult { save, discard, cancel, resume }

class StopDialogResult {
  final StopResult result;
  final ResumeSessionTarget? resumeTarget;

  const StopDialogResult(this.result, {this.resumeTarget});
}

class ResumeSessionTarget {
  final String gymId;
  final String deviceId;
  final String? exerciseId;
  final String title;

  const ResumeSessionTarget({
    required this.gymId,
    required this.deviceId,
    required this.title,
    this.exerciseId,
  });

  ResumeSessionTarget copyWith({String? title}) => ResumeSessionTarget(
        gymId: gymId,
        deviceId: deviceId,
        exerciseId: exerciseId,
        title: title ?? this.title,
      );
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
  final SessionDraftRepository _draftRepo;
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
  String? _trainingSessionId;
  final Set<String> _exerciseIds = <String>{};
  int _aggregatedSetCount = 0;
  double _aggregatedVolume = 0;
  String? _latestNote;
  bool _reportedSessionOpened = false;

  WorkoutSessionDurationService({
    FirebaseFirestore? firestore,
    WorkoutTimerTelemetry? telemetry,
    SessionDraftRepository? draftRepo,
    Duration autoStopDelay = _defaultAutoStopDelay,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _telemetry = telemetry,
        _autoStopDelay = autoStopDelay,
        _draftRepo = draftRepo ?? SessionDraftRepositoryImpl() {
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
    _trainingSessionId = null;
    _exerciseIds.clear();
    _aggregatedSetCount = 0;
    _aggregatedVolume = 0;
    _latestNote = null;
    _reportedSessionOpened = false;
    _startEpochMs = null;
    _trainingSessionId = null;
    _exerciseIds.clear();
    _aggregatedSetCount = 0;
    _aggregatedVolume = 0;
    _latestNote = null;
    _reportedSessionOpened = false;
    var shouldNotify = false;

    if (newKey != null) {
      final raw = prefs.getString(newKey) ?? await _readLegacy(uid!);
      if (raw != null) {
        try {
          final data = jsonDecode(raw) as Map<String, dynamic>;
          _startEpochMs = data['startEpochMs'] as int?;
          _firstSessionId = data['firstSessionId'] as String?;
          _lastSessionId = data['lastSessionId'] as String?;
          _trainingSessionId = data['trainingSessionId'] as String?;
          _reportedSessionOpened = data['reportedSessionOpened'] == true;
          final rawExercises = data['exerciseIds'];
          _exerciseIds
            ..clear()
            ..addAll(rawExercises is Iterable
                ? rawExercises.whereType<String>()
                : const Iterable<String>.empty());
          final setCount = data['aggregatedSetCount'];
          if (setCount is int) {
            _aggregatedSetCount = setCount;
          } else if (setCount is num) {
            _aggregatedSetCount = setCount.toInt();
          }
          final volume = data['aggregatedVolume'];
          if (volume is num) {
            _aggregatedVolume = volume.toDouble();
          }
          final latestNote = data['latestNote'];
          if (latestNote is String && latestNote.isNotEmpty) {
            _latestNote = latestNote;
          }
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
    _trainingSessionId = null;
    _exerciseIds.clear();
    _aggregatedSetCount = 0;
    _aggregatedVolume = 0;
    _latestNote = null;
    _reportedSessionOpened = false;
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
    required int setCount,
    required double totalVolume,
    String? exerciseId,
    String? note,
  }) async {
    if (!_isRunning || _startEpochMs == null) return;
    _firstSessionId ??= sessionId;
    _lastSessionId = sessionId;
    _trainingSessionId ??= _firstSessionId ?? sessionId;
    if (setCount > 0) {
      _aggregatedSetCount += setCount;
    }
    if (totalVolume > 0) {
      _aggregatedVolume += totalVolume;
    }
    if (exerciseId != null && exerciseId.isNotEmpty) {
      _exerciseIds.add(exerciseId);
    }
    if (note != null && note.trim().isNotEmpty) {
      _latestNote = note.trim();
    }
    _lastActivityEpochMs = completedAt.millisecondsSinceEpoch;
    await _persistState();
    await _syncOpenSession(activityTime: completedAt);
    _scheduleAutoStop();
  }

  Future<void> registerSetCompletion({
    required DateTime completedAt,
  }) async {
    if (!_isRunning || _startEpochMs == null) return;
    _lastActivityEpochMs = completedAt.millisecondsSinceEpoch;
    await _persistState();
    await _syncOpenSession(activityTime: completedAt, activityOnly: true);
    _scheduleAutoStop();
  }

  Future<void> registerActivity({
    required DateTime occurredAt,
  }) async {
    if (!_isRunning || _startEpochMs == null) return;
    _lastActivityEpochMs = occurredAt.millisecondsSinceEpoch;
    await _persistState();
    await _syncOpenSession(activityTime: occurredAt, activityOnly: true);
    _scheduleAutoStop();
  }

  double _durationMinutes(DateTime reference) {
    if (_startEpochMs == null) {
      return 0;
    }
    final start = DateTime.fromMillisecondsSinceEpoch(_startEpochMs!);
    final diff = reference.difference(start);
    if (diff.isNegative) {
      return 0;
    }
    return diff.inSeconds / 60.0;
  }

  Map<String, dynamic> _summaryPayload(DateTime reference) {
    return {
      'setCount': _aggregatedSetCount,
      'exerciseCount': _exerciseIds.length,
      'totalVolume': _aggregatedVolume,
      'durationMin': _durationMinutes(reference),
    };
  }

  DocumentReference<Map<String, dynamic>>? _sessionDocRef() {
    final uid = _uid;
    final gymId = _gymId;
    final sessionId = _trainingSessionId;
    if (uid == null || gymId == null || sessionId == null) {
      return null;
    }
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .doc(sessionId);
  }

  Future<void> _syncOpenSession({
    required DateTime activityTime,
    bool activityOnly = false,
  }) async {
    if (!_isRunning || _startEpochMs == null) {
      return;
    }
    _trainingSessionId ??= _firstSessionId ?? _lastSessionId;
    final ref = _sessionDocRef();
    if (ref == null) {
      return;
    }
    final summary = _summaryPayload(activityTime);
    final payload = <String, dynamic>{
      'status': 'open',
      'gymId': _gymId,
      'startedAt': Timestamp.fromMillisecondsSinceEpoch(_startEpochMs!),
      'lastActivityAt': Timestamp.fromDate(activityTime),
      'updatedAt': FieldValue.serverTimestamp(),
      'summary': summary,
    };
    if (_latestNote != null && _latestNote!.isNotEmpty) {
      payload['note'] = _latestNote;
    }
    try {
      await ref.set(payload, SetOptions(merge: true));
      if (!_reportedSessionOpened) {
        _reportedSessionOpened = true;
        _telemetry?.sessionOpened(
          sessionId: ref.id,
          gymId: _gymId!,
        );
      }
      _telemetry?.sessionActivityLogged(
        sessionId: ref.id,
        gymId: _gymId!,
        setCount: _aggregatedSetCount,
        durationMin: summary['durationMin'] as double,
      );
    } on FirebaseException {
      // fall back to local persistence only
    }
    if (!_reportedSessionOpened && !activityOnly) {
      // ensure telemetry is reported even if Firestore write fails silently
      _reportedSessionOpened = true;
      _telemetry?.sessionOpened(
        sessionId: ref.id,
        gymId: _gymId!,
      );
    }
  }

  Future<void> _finalizeSessionDocument({
    required DateTime activityReference,
    required DateTime resolvedEnd,
    required bool manual,
  }) async {
    final ref = _sessionDocRef();
    if (ref == null || _startEpochMs == null) {
      return;
    }
    final summary = _summaryPayload(resolvedEnd);
    final payload = <String, dynamic>{
      'status': 'closed',
      'gymId': _gymId,
      'startedAt': Timestamp.fromMillisecondsSinceEpoch(_startEpochMs!),
      'lastActivityAt': Timestamp.fromDate(activityReference),
      'endAt': Timestamp.fromDate(resolvedEnd),
      'updatedAt': FieldValue.serverTimestamp(),
      'summary': summary,
    };
    if (_latestNote != null && _latestNote!.isNotEmpty) {
      payload['note'] = _latestNote;
    }
    try {
      await ref.set(payload, SetOptions(merge: true));
    } on FirebaseException {
      // ignore, rely on local persistence
    }
    final durationMin = summary['durationMin'] as double;
    final setCount = summary['setCount'] as int;
    if (manual) {
      _telemetry?.sessionClosedManual(
        sessionId: ref.id,
        gymId: _gymId!,
        setCount: setCount,
        durationMin: durationMin,
      );
    } else {
      _telemetry?.sessionClosedIdle(
        sessionId: ref.id,
        gymId: _gymId!,
        setCount: setCount,
        durationMin: durationMin,
      );
    }
  }

  /// Prompts the user whether to save or discard the current session.
  ///
  /// Returns [StopResult.save] if the user chooses to persist the duration,
  /// [StopResult.discard] if it should be thrown away, [StopResult.resume]
  /// when the user wants to jump back to an unfinished session, or
  /// [StopResult.cancel] if the dialog was dismissed.
  Future<StopDialogResult> confirmStop(BuildContext context) async {
    if (!_isRunning) return const StopDialogResult(StopResult.cancel);
    final elapsedDur = elapsed;
    final locale = Localizations.localeOf(context);
    final formatted = formatDuration(elapsedDur, locale: locale);
    final loc = AppLocalizations.of(context)!;
    final resumeTargets = await _loadResumeTargets();
    final resolvedTargets = resumeTargets.length > 1
        ? await _populateResumeTargetTitles(resumeTargets)
        : resumeTargets;

    final result = await showDialog<StopDialogResult>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.sessionStopTitle),
        content: Text(loc.sessionStopMessage(formatted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(
              const StopDialogResult(StopResult.cancel),
            ),
            child: Text(loc.commonCancel),
          ),
          if (resolvedTargets.isNotEmpty)
            TextButton(
              onPressed: () async {
                if (resolvedTargets.length == 1) {
                  Navigator.of(ctx).pop(
                    StopDialogResult(
                      StopResult.resume,
                      resumeTarget: resolvedTargets.first,
                    ),
                  );
                  return;
                }
                final selection = await _showResumeSelectionDialog(
                  ctx,
                  loc,
                  resolvedTargets,
                );
                if (selection != null) {
                  Navigator.of(ctx).pop(
                    StopDialogResult(
                      StopResult.resume,
                      resumeTarget: selection,
                    ),
                  );
                }
              },
              child: Text(loc.sessionStopResumeAction),
            ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(
              const StopDialogResult(StopResult.discard),
            ),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(loc.commonDiscard),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(
              const StopDialogResult(StopResult.save),
            ),
            child: Text(loc.commonSave),
          ),
        ],
      ),
    );
    return result ?? const StopDialogResult(StopResult.cancel);
  }

  Future<List<ResumeSessionTarget>> _loadResumeTargets() async {
    final uid = _uid;
    final gymId = _gymId;
    if (uid == null || gymId == null) {
      return const <ResumeSessionTarget>[];
    }
    final drafts = await _draftRepo.getAll();
    final filtered = drafts.values.where(
      (draft) =>
          draft.userId == uid &&
          draft.gymId == gymId &&
          draft.sets.any((set) => set.done),
    );
    final sorted = filtered.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return [
      for (final draft in sorted)
        ResumeSessionTarget(
          gymId: draft.gymId,
          deviceId: draft.deviceId,
          exerciseId: draft.exerciseId,
          title: draft.exerciseId ?? draft.deviceId,
        ),
    ];
  }

  Future<List<ResumeSessionTarget>> _populateResumeTargetTitles(
    List<ResumeSessionTarget> targets,
  ) async {
    final gymId = _gymId;
    if (gymId == null) return targets;
    return Future.wait(targets.map((target) async {
      String? title;
      try {
        final deviceDoc = await _firestore
            .collection('gyms')
            .doc(gymId)
            .collection('devices')
            .doc(target.deviceId)
            .get();
        final deviceData = deviceDoc.data();
        final deviceName = deviceData?['name'] as String?;
        String? exerciseName;
        if (target.exerciseId != null) {
          final exerciseDoc = await deviceDoc.reference
              .collection('exercises')
              .doc(target.exerciseId)
              .get();
          exerciseName = exerciseDoc.data()?['name'] as String?;
        }
        final parts = [deviceName, exerciseName]
            .where((value) => value?.trim().isNotEmpty == true)
            .map((value) => value!)
            .toList();
        if (parts.isNotEmpty) {
          title = parts.join(' — ');
        }
      } catch (_) {
        // ignore lookup errors and fall back to defaults
      }
      title ??= target.exerciseId ?? target.deviceId;
      return target.copyWith(title: title);
    }));
  }

  Future<ResumeSessionTarget?> _showResumeSelectionDialog(
    BuildContext context,
    AppLocalizations loc,
    List<ResumeSessionTarget> targets,
  ) {
    return showDialog<ResumeSessionTarget>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(loc.sessionStopResumeSelectionTitle),
        children: [
          for (final target in targets)
            SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(target),
              child: Text(target.title),
            ),
        ],
      ),
    );
  }

  Future<String?> save({DateTime? endTime, String? sessionId}) async {
    if (!_isRunning || _uid == null || _gymId == null || _startEpochMs == null) {
      return null;
    }
    debugPrint(
      '⏱️ [WorkoutTimer] save requested trainingSessionId=$_trainingSessionId firstSession=$_firstSessionId lastSession=$_lastSessionId endTimeProvided=${endTime != null}',
    );
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
    _trainingSessionId ??= resolvedSessionId;

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

    final manualClosure = endTime == null;
    final now = DateTime.now();
    final lastActivity = _lastActivityEpochMs != null
        ? DateTime.fromMillisecondsSinceEpoch(_lastActivityEpochMs!)
        : end;
    final idleWindow = _autoStopDelay;
    final idleCandidate = lastActivity.add(idleWindow);
    final resolvedEndAt = manualClosure
        ? now
        : (idleCandidate.isBefore(now) ? idleCandidate : now);
    await _finalizeSessionDocument(
      activityReference: lastActivity,
      resolvedEnd: resolvedEndAt,
      manual: manualClosure,
    );

    debugPrint(
      '⏱️ [WorkoutTimer] save finalized sessionId=$resolvedSessionId manual=$manualClosure durationMs=$durationMs hasSets=$hasSets storyTrainingId=$_trainingSessionId',
    );

    await _clearLocal();
    return resolvedSessionId;
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
      if (_trainingSessionId != null) 'trainingSessionId': _trainingSessionId,
      'aggregatedSetCount': _aggregatedSetCount,
      'aggregatedVolume': _aggregatedVolume,
      if (_exerciseIds.isNotEmpty) 'exerciseIds': _exerciseIds.toList(),
      if (_latestNote != null) 'latestNote': _latestNote,
      'reportedSessionOpened': _reportedSessionOpened,
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
      unawaited(_autoFinalize());
    } else {
      _autoStopTimer = Timer(_autoStopDelay, () {
        unawaited(_autoFinalize());
      });
    }
  }

  void _resumeAutoStopTimer() {
    if (!_isRunning || _lastActivityEpochMs == null) return;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final target = _lastActivityEpochMs! + _autoStopDelay.inMilliseconds;
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
    if (!_isRunning || _startEpochMs == null || _lastActivityEpochMs == null) {
      return;
    }
    final end = DateTime.fromMillisecondsSinceEpoch(_lastActivityEpochMs!);
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


