import 'dart:async';

import 'package:flutter/foundation.dart';

/// Simple state machine for cardio timer.
/// States: idle -> running -> stopped.
class CardioTimerProvider extends ChangeNotifier {
  CardioTimerState _state = CardioTimerState.idle;
  DateTime? _startedAt;
  int _elapsedSec = 0; // accumulated seconds when stopped
  Timer? _ticker;

  CardioTimerState get state => _state;

  /// Elapsed seconds depending on state.
  int get elapsedSec {
    if (_state == CardioTimerState.running && _startedAt != null) {
      return _elapsedSec + DateTime.now().difference(_startedAt!).inSeconds;
    }
    return _elapsedSec;
  }

  bool get isRunning => _state == CardioTimerState.running;
  bool get isStopped => _state == CardioTimerState.stopped;

  void start() {
    if (_state == CardioTimerState.running) return;
    _startedAt = DateTime.now();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => notifyListeners());
    _state = CardioTimerState.running;
    notifyListeners();
  }

  void pause() {
    if (_state != CardioTimerState.running) return;
    _elapsedSec = elapsedSec;
    _ticker?.cancel();
    _ticker = null;
    _startedAt = null;
    _state = CardioTimerState.stopped;
    notifyListeners();
  }

  void reset() {
    _ticker?.cancel();
    _ticker = null;
    _startedAt = null;
    _elapsedSec = 0;
    _state = CardioTimerState.idle;
    notifyListeners();
  }
}

enum CardioTimerState { idle, running, stopped }

