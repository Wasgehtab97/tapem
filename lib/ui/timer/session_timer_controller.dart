import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

class SessionTimerController {
  SessionTimerController({
    required this.total,
    bool initiallyRunning = false,
    this.onTick,
    this.onDone,
    required TickerProvider vsync,
  })  : remaining = ValueNotifier(total),
        running = ValueNotifier(initiallyRunning) {
    _ticker = vsync.createTicker(_onTick);
    if (initiallyRunning) {
      _ticker.start();
    }
  }

  final Duration total;
  final ValueNotifier<Duration> remaining;
  final ValueNotifier<bool> running;
  final ValueChanged<Duration>? onTick;
  final VoidCallback? onDone;

  late final Ticker _ticker;
  Duration _elapsed = Duration.zero;
  Duration _lastTick = Duration.zero;

  void _onTick(Duration elapsed) {
    final dt = elapsed - _lastTick;
    _lastTick = elapsed;
    _elapsed += dt;
    final left = total - _elapsed;
    if (left <= Duration.zero) {
      remaining.value = Duration.zero;
      running.value = false;
      _ticker.stop();
      onTick?.call(Duration.zero);
      onDone?.call();
    } else {
      remaining.value = left;
      onTick?.call(left);
    }
  }

  void start() {
    reset();
    resume();
  }

  void pause() {
    if (!running.value) return;
    running.value = false;
    _ticker.stop();
    _elapsed += _lastTick;
    _lastTick = Duration.zero;
  }

  void resume() {
    if (running.value) return;
    running.value = true;
    _lastTick = Duration.zero;
    _ticker.start();
  }

  void reset() {
    _ticker.stop();
    _elapsed = Duration.zero;
    _lastTick = Duration.zero;
    remaining.value = total;
    running.value = false;
  }

  void dispose() {
    _ticker.dispose();
    remaining.dispose();
    running.dispose();
  }
}

