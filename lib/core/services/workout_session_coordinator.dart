import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tapem/core/config/workout_inactivity_config.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/time/logic_day.dart';

import 'workout_session_duration_service.dart';

void _workoutFlowLog(String message) {
  debugPrint('🏁 [WorkoutFlow] $message');
}

void _workoutFlowError(String message, StackTrace stackTrace) {
  debugPrint('❌ [WorkoutFlow] $message');
  debugPrintStack(label: 'workout_flow_error', stackTrace: stackTrace);
}

enum WorkoutFinalizeReason {
  manualSave,
  manualStop,
  autoInactivity,
  discardNoSets,
}

class WorkoutSessionCoordinator extends ChangeNotifier
    with WidgetsBindingObserver {
  static const _prefsKeyPrefix = 'workoutCoordinator:';
  static const _prefsKeyDelimiter = '::';
  static const _defaultInactivityDelay = kWorkoutInactivityDuration;
  static const _defaultAutoFinalizeRetryDelay = Duration(seconds: 30);

  WorkoutSessionCoordinator({
    required WorkoutSessionDurationService durationService,
    Duration inactivityDelay = _defaultInactivityDelay,
    Duration autoFinalizeRetryDelay = _defaultAutoFinalizeRetryDelay,
  }) : _durationService = durationService,
       _inactivityDelay = inactivityDelay,
       _autoFinalizeRetryDelay = autoFinalizeRetryDelay {
    WidgetsBinding.instance.addObserver(this);
    _workoutFlowLog(
      'coordinator_init thresholdMin=$kWorkoutInactivityMinutes thresholdMs=${_inactivityDelay.inMilliseconds} retryMs=${_autoFinalizeRetryDelay.inMilliseconds}',
    );
  }

  final WorkoutSessionDurationService _durationService;
  final Duration _inactivityDelay;
  final Duration _autoFinalizeRetryDelay;
  SharedPreferences? _prefs;
  Timer? _inactivityTimer;
  Future<void> Function(DateTime lastSetCompletedAt)? _autoFinalizeHandler;
  bool _autoFinalizeInFlight = false;
  bool _isDisposed = false;

  String? _uid;
  String? _gymId;
  String? _activePrefsKey;

  bool _isRunning = false;
  int? _anchorStartEpochMs;
  String? _anchorDayKey;
  int? _lastSetCompletedEpochMs;
  int? _finalizedEpochMs;
  String? _finalizeReason;
  String? _finalizeToken;

  bool get isRunning => _isRunning;
  bool get isDisposed => _isDisposed;
  DateTime? get anchorStartAt => _fromMs(_anchorStartEpochMs);
  String? get anchorDayKey => _anchorDayKey;
  DateTime? get lastSetCompletedAt => _fromMs(_lastSetCompletedEpochMs);
  DateTime? get finalizedAt => _fromMs(_finalizedEpochMs);
  String? get finalizeReason => _finalizeReason;
  String? get finalizeToken => _finalizeToken;

  Future<void> setActiveContext({String? uid, String? gymId}) async {
    if (_isDisposed) return;
    await _ensurePrefs();
    if (_isDisposed) return;
    final newKey = (uid != null && gymId != null && gymId.isNotEmpty)
        ? _prefsKeyFor(uid, gymId)
        : null;

    if (_activePrefsKey == newKey && _uid == uid && _gymId == gymId) {
      return;
    }

    _uid = uid;
    _gymId = gymId;
    _activePrefsKey = newKey;
    _resetInMemory();

    if (newKey == null) {
      _notifyListenersSafely();
      return;
    }

    final raw = _prefs!.getString(newKey);
    if (raw != null) {
      _restore(raw);
    }
    final recoveredLastSet = _recoverLastSetFromDurationIfMissing();
    if (recoveredLastSet) {
      unawaited(_persistState());
    }

    _resumeInactivityTimer();

    _notifyListenersSafely();
  }

  Future<void> evaluateInactivityNow({String? uid, String? gymId}) async {
    if (_isDisposed) return;
    if (uid != null && gymId != null && gymId.isNotEmpty) {
      await setActiveContext(uid: uid, gymId: gymId);
      if (_isDisposed) return;
    }
    _resumeInactivityTimer();
  }

  Future<void> startFromProfilePlay({
    required String uid,
    required String gymId,
    DateTime? startedAt,
  }) async {
    if (_isDisposed) return;
    await setActiveContext(uid: uid, gymId: gymId);
    if (_isDisposed) return;
    if (_isRunning && !_durationService.isRunning) {
      // Recover from stale "running" marker when the timer is already idle.
      _isRunning = false;
    }
    if (_isRunning) return;

    final start = startedAt ?? DateTime.now();
    _workoutFlowLog(
      'session_start source=profile_play uid=$uid gym=$gymId start=${start.toIso8601String()}',
    );
    _isRunning = true;
    _anchorStartEpochMs = start.millisecondsSinceEpoch;
    _anchorDayKey = logicDayKey(start);
    _lastSetCompletedEpochMs = null;
    _finalizedEpochMs = null;
    _finalizeReason = null;
    _finalizeToken = null;

    _cancelInactivityTimer();
    await _persistState();
    if (_isDisposed) return;
    if (!_durationService.isRunning) {
      await _durationService.start(uid: uid, gymId: gymId);
      if (_isDisposed) return;
    }
    _notifyListenersSafely();
  }

  Future<void> onExerciseAddedFromGymOrNfc({
    required String uid,
    required String gymId,
  }) async {
    if (_isDisposed) return;
    await setActiveContext(uid: uid, gymId: gymId);
    if (_isDisposed) return;
    // Explicit intent to start a new set-driven session after a previous
    // finalize. We only clear finalize markers on an actual add-intent event
    // (Gym/NFC), not on arbitrary late set callbacks.
    if (!_isRunning && (_finalizedEpochMs != null || _finalizeReason != null)) {
      _workoutFlowLog('session_rearm source=gym_or_nfc uid=$uid gym=$gymId');
      _finalizedEpochMs = null;
      _finalizeReason = null;
      _finalizeToken = null;
      await _persistState();
      if (_isDisposed) return;
      _notifyListenersSafely();
    }
  }

  Future<void> onFirstSetCompleted({
    required String uid,
    required String gymId,
    DateTime? completedAt,
  }) async {
    await _registerSetCompletion(
      uid: uid,
      gymId: gymId,
      completedAt: completedAt ?? DateTime.now(),
    );
  }

  Future<void> onSetCompleted({
    required String uid,
    required String gymId,
    DateTime? completedAt,
  }) async {
    await _registerSetCompletion(
      uid: uid,
      gymId: gymId,
      completedAt: completedAt ?? DateTime.now(),
    );
  }

  Future<void> markSessionFinalized({
    required WorkoutFinalizeReason reason,
    DateTime? finalizedAt,
  }) async {
    if (_isDisposed) return;
    final resolvedFinalizedAt = finalizedAt ?? DateTime.now();
    final finalizedAtMs = resolvedFinalizedAt.millisecondsSinceEpoch;
    final requestedToken = _buildFinalizeToken(
      reason: reason.name,
      finalizedAtMs: finalizedAtMs,
    );
    if (!_isRunning && _finalizedEpochMs != null) {
      final existingReason = _finalizeReason ?? 'unknown';
      final existingAtMs = _finalizedEpochMs!;
      final existingAt = DateTime.fromMillisecondsSinceEpoch(existingAtMs);
      final existingToken =
          _finalizeToken ??
          _buildFinalizeToken(
            reason: existingReason,
            finalizedAtMs: existingAtMs,
          );
      _finalizeToken = existingToken;
      _workoutFlowLog(
        'finalize_skipped_duplicate requestedReason=${reason.name} requestedAt=${resolvedFinalizedAt.toIso8601String()} requestedToken=$requestedToken existingReason=$existingReason existingAt=${existingAt.toIso8601String()} existingToken=$existingToken',
      );
      return;
    }
    _isRunning = false;
    _finalizedEpochMs = finalizedAtMs;
    _finalizeReason = reason.name;
    _finalizeToken = requestedToken;
    _workoutFlowLog(
      'session_finalized reason=${reason.name} token=$requestedToken anchorDay=$_anchorDayKey finalizedAt=${DateTime.fromMillisecondsSinceEpoch(_finalizedEpochMs!).toIso8601String()} lastSet=${lastSetCompletedAt?.toIso8601String()}',
    );
    _cancelInactivityTimer();
    if (_activePrefsKey != null) {
      await _persistState();
    }
    if (_isDisposed) return;
    _notifyListenersSafely();
  }

  Future<void> finishDiscarded({
    WorkoutFinalizeReason reason = WorkoutFinalizeReason.manualStop,
  }) async {
    if (_isDisposed) return;
    if (_durationService.isRunning) {
      await _durationService.discard();
    }
    await markSessionFinalized(reason: reason, finalizedAt: DateTime.now());
  }

  Future<void> finishManuallyFromWorkoutSave({DateTime? finalizedAt}) async {
    if (_isDisposed) return;
    await markSessionFinalized(
      reason: WorkoutFinalizeReason.manualSave,
      finalizedAt: finalizedAt ?? DateTime.now(),
    );
  }

  Future<void> finishManuallyFromProfileStop({DateTime? finalizedAt}) async {
    if (_isDisposed) return;
    if (_durationService.isRunning) {
      await _durationService.discard();
    }
    await markSessionFinalized(
      reason: WorkoutFinalizeReason.manualStop,
      finalizedAt: finalizedAt ?? DateTime.now(),
    );
  }

  Future<void> finishAutomaticallyAfterInactivity({
    required DateTime lastSetCompletedAt,
  }) async {
    if (_isDisposed) return;
    await markSessionFinalized(
      reason: WorkoutFinalizeReason.autoInactivity,
      finalizedAt: lastSetCompletedAt,
    );
  }

  Future<void> _registerSetCompletion({
    required String uid,
    required String gymId,
    required DateTime completedAt,
  }) async {
    if (_isDisposed) return;
    await setActiveContext(uid: uid, gymId: gymId);
    if (_isDisposed) return;
    final completedAtMs = completedAt.millisecondsSinceEpoch;
    if (!_isRunning) {
      // A finalized session can only be restarted via an explicit new start
      // intent (profile play or Gym/NFC add). This blocks late async set
      // callbacks from reviving a completed training.
      if (_finalizedEpochMs != null || _finalizeReason != null) {
        return;
      }
      _isRunning = true;
      _anchorStartEpochMs = completedAtMs;
      _anchorDayKey = logicDayKey(completedAt);
      _workoutFlowLog(
        'session_start source=first_set uid=$uid gym=$gymId start=${completedAt.toIso8601String()}',
      );
      _finalizedEpochMs = null;
      _finalizeReason = null;
      _finalizeToken = null;
      if (!_durationService.isRunning) {
        await _durationService.start(uid: uid, gymId: gymId);
        if (_isDisposed) return;
      }
    } else if (_finalizedEpochMs != null || _finalizeReason != null) {
      // Defensive cleanup: a running session must not carry finalized metadata.
      _finalizedEpochMs = null;
      _finalizeReason = null;
      _finalizeToken = null;
    }
    _lastSetCompletedEpochMs = completedAtMs;
    final dueAtMs = completedAtMs + _inactivityDelay.inMilliseconds;
    _workoutFlowLog(
      'set_completed uid=$uid gym=$gymId at=$completedAtMs dueAt=$dueAtMs',
    );
    _scheduleInactivityTimer();
    await _persistState();
    if (_isDisposed) return;
    await _durationService.registerSetCompletion(completedAt: completedAt);
    if (_isDisposed) return;
    _notifyListenersSafely();
  }

  void setAutoFinalizeHandler(
    Future<void> Function(DateTime lastSetCompletedAt)? handler,
  ) {
    if (_isDisposed) return;
    _autoFinalizeHandler = handler;
    _resumeInactivityTimer();
  }

  void _restore(String raw) {
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      _isRunning = data['isRunning'] == true;
      _anchorStartEpochMs = data['anchorStartEpochMs'] as int?;
      _anchorDayKey = data['anchorDayKey'] as String?;
      _lastSetCompletedEpochMs = data['lastSetCompletedEpochMs'] as int?;
      _finalizedEpochMs = data['finalizedEpochMs'] as int?;
      _finalizeReason = data['finalizeReason'] as String?;
      _finalizeToken = data['finalizeToken'] as String?;
      if (_finalizeToken == null &&
          _finalizedEpochMs != null &&
          _finalizeReason != null) {
        _finalizeToken = _buildFinalizeToken(
          reason: _finalizeReason!,
          finalizedAtMs: _finalizedEpochMs!,
        );
      }
    } catch (_) {
      _resetInMemory();
    }
  }

  Future<void> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> _persistState() async {
    if (_isDisposed) return;
    final key = _activePrefsKey;
    if (key == null) return;
    await _ensurePrefs();
    if (_isDisposed) return;
    final payload = <String, dynamic>{
      'isRunning': _isRunning,
      'anchorStartEpochMs': _anchorStartEpochMs,
      'anchorDayKey': _anchorDayKey,
      'lastSetCompletedEpochMs': _lastSetCompletedEpochMs,
      'finalizedEpochMs': _finalizedEpochMs,
      'finalizeReason': _finalizeReason,
      'finalizeToken': _finalizeToken,
    };
    await _prefs!.setString(key, jsonEncode(payload));
  }

  void _notifyListenersSafely() {
    if (_isDisposed) return;
    notifyListeners();
  }

  String _prefsKeyFor(String uid, String gymId) =>
      '$_prefsKeyPrefix$uid$_prefsKeyDelimiter$gymId';

  DateTime? _fromMs(int? value) {
    if (value == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(value);
  }

  String _buildFinalizeToken({
    required String reason,
    required int finalizedAtMs,
  }) {
    final uid = _uid ?? 'unknown';
    final gym = _gymId ?? 'unknown';
    final anchorDay = _anchorDayKey ?? 'unknown';
    return '$uid|$gym|$anchorDay|$reason|$finalizedAtMs';
  }

  void _resetInMemory() {
    _cancelInactivityTimer();
    _autoFinalizeInFlight = false;
    _isRunning = false;
    _anchorStartEpochMs = null;
    _anchorDayKey = null;
    _lastSetCompletedEpochMs = null;
    _finalizedEpochMs = null;
    _finalizeReason = null;
    _finalizeToken = null;
  }

  void _scheduleInactivityTimer() {
    if (!_isRunning) return;
    _cancelInactivityTimer();
    if (_inactivityDelay <= Duration.zero) {
      unawaited(_handleInactivityTimeout());
      return;
    }
    final dueAtMs =
        (_lastSetCompletedEpochMs ?? DateTime.now().millisecondsSinceEpoch) +
        _inactivityDelay.inMilliseconds;
    _workoutFlowLog(
      'inactivity_timer_scheduled source=set_completion dueAt=$dueAtMs',
    );
    _inactivityTimer = Timer(_inactivityDelay, () {
      unawaited(_handleInactivityTimeout());
    });
  }

  void _resumeInactivityTimer() {
    _cancelInactivityTimer();
    if (!_isRunning) return;
    if (_recoverLastSetFromDurationIfMissing()) {
      unawaited(_persistState());
    }
    final lastMs = _lastSetCompletedEpochMs;
    if (lastMs == null) return;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final targetMs = lastMs + _inactivityDelay.inMilliseconds;
    final remainingMs = targetMs - nowMs;
    if (remainingMs <= 0) {
      _workoutFlowLog(
        'inactivity_resume_due now=$nowMs target=$targetMs remainingMs=$remainingMs',
      );
      unawaited(_handleInactivityTimeout());
      return;
    }
    _workoutFlowLog(
      'inactivity_timer_scheduled source=resume dueAt=$targetMs remainingMs=$remainingMs',
    );
    _inactivityTimer = Timer(Duration(milliseconds: remainingMs), () {
      unawaited(_handleInactivityTimeout());
    });
  }

  Future<void> _handleInactivityTimeout() async {
    if (_isDisposed) return;
    if (_autoFinalizeInFlight) return;
    if (!_isRunning) return;
    final lastMs = _lastSetCompletedEpochMs;
    if (lastMs == null) return;
    final dueAtMs = lastMs + _inactivityDelay.inMilliseconds;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    _workoutFlowLog('inactivity_timeout_check now=$nowMs dueAt=$dueAtMs');
    if (nowMs < dueAtMs) {
      _resumeInactivityTimer();
      return;
    }
    _workoutFlowLog(
      'auto_finalize_due anchorDay=$_anchorDayKey lastSet=${DateTime.fromMillisecondsSinceEpoch(lastMs).toIso8601String()}',
    );
    final handler = _autoFinalizeHandler;
    if (handler == null) {
      _workoutFlowLog('auto_finalize_handler_missing');
      _scheduleRetry(reason: 'missing_handler');
      return;
    }
    final lastSetAt = DateTime.fromMillisecondsSinceEpoch(lastMs);
    _autoFinalizeInFlight = true;
    try {
      _workoutFlowLog(
        'auto_finalize_handler_invoke lastSet=${lastSetAt.toIso8601String()}',
      );
      await handler(lastSetAt);
      _workoutFlowLog(
        'auto_finalize_handler_success lastSet=${lastSetAt.toIso8601String()}',
      );
    } catch (error, stackTrace) {
      _workoutFlowError(
        'auto_finalize_handler_failed error=$error; scheduling_retry',
        stackTrace,
      );
      _scheduleRetry(reason: 'handler_failure');
    } finally {
      _autoFinalizeInFlight = false;
    }

    if (_isRunning) {
      _workoutFlowLog('auto_finalize_handler_completed_but_session_running');
      _scheduleRetry(reason: 'session_still_running');
    }
  }

  void _scheduleRetry({required String reason}) {
    if (!_isRunning) return;
    _cancelInactivityTimer();
    _workoutFlowLog(
      'auto_finalize_retry_scheduled reason=$reason delayMs=${_autoFinalizeRetryDelay.inMilliseconds}',
    );
    _inactivityTimer = Timer(_autoFinalizeRetryDelay, () {
      unawaited(_handleInactivityTimeout());
    });
  }

  void _cancelInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }

  bool _recoverLastSetFromDurationIfMissing() {
    if (!_isRunning || _lastSetCompletedEpochMs != null) {
      return false;
    }
    final lastActivityAt = _durationService.lastActivityTime;
    if (lastActivityAt == null) {
      return false;
    }
    final lastActivityMs = lastActivityAt.millisecondsSinceEpoch;
    final anchorMs = _anchorStartEpochMs;
    if (anchorMs != null && lastActivityMs < anchorMs) {
      return false;
    }
    _lastSetCompletedEpochMs = lastActivityMs;
    _workoutFlowLog(
      'recovered_last_set_from_duration at=${lastActivityAt.toIso8601String()}',
    );
    return true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) return;
    if (state == AppLifecycleState.resumed) {
      // Timers are suspended in background on iOS/Android. Re-evaluate
      // inactivity immediately on resume to avoid stuck overnight sessions.
      _resumeInactivityTimer();
    }
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _cancelInactivityTimer();
    super.dispose();
  }
}

final ChangeNotifierProvider<WorkoutSessionCoordinator>
workoutSessionCoordinatorProvider =
    ChangeNotifierProvider<WorkoutSessionCoordinator>((ref) {
      final coordinator = WorkoutSessionCoordinator(
        durationService: ref.read(workoutSessionDurationServiceProvider),
      );

      Future<void> update(AuthViewState state) {
        return coordinator.setActiveContext(
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
      ref.onDispose(() => coordinator.setAutoFinalizeHandler(null));
      return coordinator;
    });
