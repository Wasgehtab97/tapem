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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final progress = _remaining / _duration;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          height: 80,
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
        const SizedBox(height: 8),
        Row(
          children: [
            Text('${loc.timerDuration}:'),
            const SizedBox(width: 8),
            DropdownButton<int>(
              value: _duration,
              items: [
                for (final d in _presetDurations)
                  DropdownMenuItem(
                    value: d,
                    child: Text('$d${loc.secondsAbbreviation}'),
                  ),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _duration = v;
                  _remaining = v;
                });
              },
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: _toggleTimer,
              child: Text(_running ? loc.timerStop : loc.timerStart),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: _resetTimer,
              child: Text(loc.timerReset),
            ),
          ],
        ),
      ],
    );
  }
}
