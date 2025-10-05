import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'package:tapem/services/audio/timer_audio_service.dart';

import 'session_timer_controller.dart';

class SessionTimerService extends ChangeNotifier {
  SessionTimerService({
    Duration? initialDuration,
    Duration preAlertAt = const Duration(seconds: 3),
    TimerAudioService? audioService,
  })  : _preAlertAt = preAlertAt,
        _audioService = audioService ?? TimerAudioService() {
    final initialSeconds = initialDuration?.inSeconds ?? _durations[_defaultIndex];
    final matchedIndex = _durations.indexOf(initialSeconds);
    _selectedIndex = matchedIndex == -1 ? _defaultIndex : matchedIndex;
    _controller = SessionTimerController(
      total: Duration(seconds: _durations[_selectedIndex]),
      onTick: _handleTick,
      onDone: _handleDone,
    );
    _preAlertEligible = _isPreAlertEnabledFor(_controller.total);
    unawaited(_audioService.preload());
  }

  static const _durations = [60, 90, 120, 150, 180];
  static const _defaultIndex = 1;

  late final SessionTimerController _controller;
  int _selectedIndex = _defaultIndex;
  bool _hasUserInteraction = false;
  bool _preAlertFired = false;
  bool _preAlertEligible = true;
  late Duration _preAlertAt;

  final List<ValueChanged<Duration>> _tickListeners = <ValueChanged<Duration>>[];
  final List<VoidCallback> _doneListeners = <VoidCallback>[];
  final TimerAudioService _audioService;

  UnmodifiableListView<int> get availableDurations =>
      UnmodifiableListView(_durations);

  int get selectedIndex => _selectedIndex;

  Duration get selectedDuration =>
      Duration(seconds: _durations[_selectedIndex]);

  ValueListenable<Duration> get remaining => _controller.remaining;
  ValueListenable<bool> get running => _controller.running;

  Duration get total => _controller.total;

  bool get isRunning => _controller.running.value;

  Duration get preAlertAt => _preAlertAt;
  set preAlertAt(Duration value) {
    _preAlertAt = value;
    _preAlertEligible = _isPreAlertEnabledFor(total);
    if (_preAlertAt <= Duration.zero) {
      _preAlertFired = false;
      return;
    }
    if (remaining.value > _preAlertAt) {
      _preAlertFired = false;
    }
  }

  void addTickListener(ValueChanged<Duration> listener) {
    if (!_tickListeners.contains(listener)) {
      _tickListeners.add(listener);
    }
  }

  void removeTickListener(ValueChanged<Duration> listener) {
    _tickListeners.remove(listener);
  }

  void addDoneListener(VoidCallback listener) {
    if (!_doneListeners.contains(listener)) {
      _doneListeners.add(listener);
    }
  }

  void removeDoneListener(VoidCallback listener) {
    _doneListeners.remove(listener);
  }

  void applyInitialDuration(Duration duration) {
    if (_hasUserInteraction) return;
    final seconds = duration.inSeconds;
    final idx = _durations.indexOf(seconds);
    if (idx == -1 || idx == _selectedIndex) return;
    _selectedIndex = idx;
    if (!isRunning) {
      _controller.setTotal(selectedDuration);
    }
    notifyListeners();
  }

  void changeDuration(int delta) {
    final newIndex = (_selectedIndex + delta).clamp(0, _durations.length - 1);
    if (newIndex == _selectedIndex) return;
    _selectedIndex = newIndex;
    _hasUserInteraction = true;
    if (!isRunning) {
      _controller.setTotal(selectedDuration);
    }
    notifyListeners();
  }

  void start() {
    startWith(selectedDuration);
  }

  void startWith(Duration total) {
    _hasUserInteraction = true;
    _preAlertFired = false;
    _preAlertEligible = _isPreAlertEnabledFor(total);
    _controller.startWith(total);
  }

  void stop() {
    _hasUserInteraction = true;
    _preAlertFired = false;
    _preAlertEligible = true;
    _controller.reset();
  }

  void _handleTick(Duration remaining) {
    if (_shouldFirePreAlert(remaining)) {
      _preAlertFired = true;
      unawaited(_audioService.playPreAlert());
    }
    for (final listener in List<ValueChanged<Duration>>.from(_tickListeners)) {
      listener(remaining);
    }
  }

  void _handleDone() {
    _preAlertFired = false;
    _preAlertEligible = true;
    unawaited(_audioService.playEnd());
    for (final listener in List<VoidCallback>.from(_doneListeners)) {
      listener();
    }
  }

  bool _shouldFirePreAlert(Duration remaining) {
    if (_preAlertFired || !_preAlertEligible) return false;
    if (!isRunning) return false;
    if (_preAlertAt <= Duration.zero) return false;
    if (remaining <= Duration.zero) return false;
    return remaining <= _preAlertAt;
  }

  bool _isPreAlertEnabledFor(Duration total) {
    if (_preAlertAt <= Duration.zero) {
      return false;
    }
    return total > _preAlertAt;
  }

  @override
  void dispose() {
    _controller.dispose();
    unawaited(_audioService.dispose());
    super.dispose();
  }
}
