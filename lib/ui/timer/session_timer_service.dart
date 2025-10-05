import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'session_timer_controller.dart';

class SessionTimerService extends ChangeNotifier {
  SessionTimerService({Duration? initialDuration}) {
    final initialSeconds = initialDuration?.inSeconds ?? _durations[_defaultIndex];
    final matchedIndex = _durations.indexOf(initialSeconds);
    _selectedIndex = matchedIndex == -1 ? _defaultIndex : matchedIndex;
    _controller = SessionTimerController(
      total: Duration(seconds: _durations[_selectedIndex]),
      onTick: _handleTick,
    );
  }

  static const _durations = [60, 90, 120, 150, 180];
  static const _defaultIndex = 1;

  late final SessionTimerController _controller;
  int _selectedIndex = _defaultIndex;
  bool _hasUserInteraction = false;

  final List<ValueChanged<Duration>> _tickListeners = <ValueChanged<Duration>>[];

  UnmodifiableListView<int> get availableDurations =>
      UnmodifiableListView(_durations);

  int get selectedIndex => _selectedIndex;

  Duration get selectedDuration =>
      Duration(seconds: _durations[_selectedIndex]);

  ValueListenable<Duration> get remaining => _controller.remaining;
  ValueListenable<bool> get running => _controller.running;

  Duration get total => _controller.total;

  bool get isRunning => _controller.running.value;

  void addTickListener(ValueChanged<Duration> listener) {
    if (!_tickListeners.contains(listener)) {
      _tickListeners.add(listener);
    }
  }

  void removeTickListener(ValueChanged<Duration> listener) {
    _tickListeners.remove(listener);
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
    _controller.startWith(total);
  }

  void stop() {
    _hasUserInteraction = true;
    _controller.reset();
  }

  void _handleTick(Duration remaining) {
    for (final listener in List<ValueChanged<Duration>>.from(_tickListeners)) {
      listener(remaining);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
