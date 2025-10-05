import 'dart:async';

import 'package:uuid/uuid.dart';

import '../../core/audio/timer_chime_player.dart';
import '../../core/logging/app_logger.dart';

class SessionTimerChimeCoordinator {
  SessionTimerChimeCoordinator({
    required TimerChimePlayer player,
    Duration leadTime = const Duration(seconds: 3),
  })  : _player = player,
        _leadTime = leadTime;

  final TimerChimePlayer _player;
  final Duration _leadTime;
  final _uuid = const Uuid();

  Timer? _chimeTimer;
  Stopwatch? _stopwatch;
  Duration? _scheduledDelay;

  String? _timerId;
  DateTime? _tStart;
  DateTime? _tEnd;
  DateTime? _tChime;

  Future<void> onTimerStart({
    required Duration total,
    required Duration remaining,
  }) async {
    _cancelChimeTimer();
    final timerId = _uuid.v4();
    _timerId = timerId;
    _tStart = DateTime.now().toUtc();
    _tEnd = _tStart!.add(remaining);
    _tChime = _tEnd!.subtract(_leadTime);
    final delay = remaining - _leadTime;
    final clampedDelay = delay.isNegative ? Duration.zero : delay;
    _stopwatch = Stopwatch()..start();
    _scheduledDelay = clampedDelay;

    logAppEvent(
      category: AppLogCategory.timer,
      name: 'TIMER_START',
      timerId: timerId,
      details: {
        'tStart': _tStart!,
        'tEnd': _tEnd!,
        'tChime': _tChime!,
        'durationSec': total.inSeconds,
        'remainingSec': remaining.inSeconds,
      },
    );

    unawaited(_player.configureForTimer(timerId: timerId));

    if (clampedDelay == Duration.zero) {
      _triggerChime();
    } else {
      _chimeTimer = Timer(clampedDelay, _triggerChime);
    }
  }

  void onTimerPauseOrStop() {
    _cancelChimeTimer();
    _stopwatch?.stop();
    _stopwatch = null;
    _scheduledDelay = null;
    _timerId = null;
  }

  Future<void> onTimerEnd({
    required FutureOr<void> Function()? onNavigate,
  }) async {
    final timerId = _timerId;
    if (timerId == null) {
      await onNavigate?.call();
      return;
    }

    logAppEvent(
      category: AppLogCategory.timer,
      name: 'TIMER_END_REACHED',
      timerId: timerId,
      details: {
        'tEnd': DateTime.now().toUtc(),
      },
    );

    final completed = await _player.waitForCompletion(timerId: timerId);

    if (!completed) {
      logAppEvent(
        category: AppLogCategory.timer,
        name: 'NAVIGATE_AFTER_AUDIO',
        level: AppLogLevel.warning,
        timerId: timerId,
        details: {
          'reason': 'timeout',
        },
      );
    } else {
      logAppEvent(
        category: AppLogCategory.timer,
        name: 'NAVIGATE_AFTER_AUDIO',
        timerId: timerId,
        details: {
          'reason': 'completed',
        },
      );
    }

    await onNavigate?.call();
    _cancelChimeTimer();
    _stopwatch?.stop();
    _stopwatch = null;
    _scheduledDelay = null;
    _timerId = null;
  }

  void _triggerChime() {
    final timerId = _timerId;
    if (timerId == null) {
      return;
    }
    final now = DateTime.now().toUtc();
    final deltaToEnd = _tEnd != null ? _tEnd!.difference(now) : Duration.zero;
    final drift = _computeDrift();
    if (drift.abs() > const Duration(milliseconds: 50)) {
      logAppEvent(
        category: AppLogCategory.timer,
        name: 'TIMER_DRIFT',
        level: AppLogLevel.warning,
        timerId: timerId,
        details: {
          'driftMs': drift.inMilliseconds,
        },
      );
    }

    logAppEvent(
      category: AppLogCategory.timer,
      name: 'CHIME_SCHEDULED',
      timerId: timerId,
      details: {
        'now': now,
        'deltaToEndMs': deltaToEnd.inMilliseconds,
        'assetKey': _player.currentAssetKey,
      },
    );

    unawaited(_player.play(timerId: timerId));
  }

  Duration _computeDrift() {
    final elapsed = _stopwatch?.elapsed ?? Duration.zero;
    final expected = _scheduledDelay ?? Duration.zero;
    return elapsed - expected;
  }

  void _cancelChimeTimer() {
    _chimeTimer?.cancel();
    _chimeTimer = null;
  }
}
