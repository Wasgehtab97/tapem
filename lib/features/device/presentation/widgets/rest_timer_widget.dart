import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Ein einfacher Rest-Timer mit Start/Stop-Button.
class RestTimerWidget extends StatefulWidget {
  final int initialSeconds;
  const RestTimerWidget({Key? key, this.initialSeconds = 90}) : super(key: key);

  @override
  State<RestTimerWidget> createState() => _RestTimerWidgetState();
}

class _RestTimerWidgetState extends State<RestTimerWidget> {
  static const _presetDurations = [60, 90, 120, 150, 180];

  late int _duration;
  late int _remaining;
  Timer? _timer;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _duration = widget.initialSeconds;
    _remaining = _duration;
  }

  void _toggleTimer() {
    if (_running) {
      _timer?.cancel();
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_remaining <= 0) {
          t.cancel();
          setState(() => _running = false);
        } else {
          setState(() => _remaining--);
        }
      });
    }
    setState(() => _running = !_running);
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _remaining = _duration;
    });
  }

  void _cycleDuration() {
    final currentIndex = _presetDurations.indexOf(_duration);
    final nextIndex = (currentIndex + 1) % _presetDurations.length;
    setState(() {
      _duration = _presetDurations[nextIndex];
      _remaining = _duration;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final progress = _remaining / _duration;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
          onPressed: _toggleTimer,
          icon: Icon(_running ? Icons.pause : Icons.play_arrow),
          tooltip: _running ? loc.timerStop : loc.timerStart,
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _resetTimer,
          icon: const Icon(Icons.replay),
          tooltip: loc.timerReset,
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _cycleDuration,
          child: SizedBox(
            width: 150,
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: 1 - progress,
                  strokeWidth: 6,
                ),
                Text('$_remaining${loc.secondsAbbreviation}'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
