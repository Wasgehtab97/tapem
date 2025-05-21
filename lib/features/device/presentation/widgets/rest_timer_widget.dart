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
  late int _remaining;
  Timer? _timer;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.initialSeconds;
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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Row(
      children: [
        Text('${loc.timerPauseLabel}: $_remaining ${loc.secondsAbbreviation}'),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: _toggleTimer,
          child: Text(_running ? loc.timerStop : loc.timerStart),
        ),
      ],
    );
  }
}
