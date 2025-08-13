import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'session_timer_controller.dart';
import 'package:tapem/l10n/app_localizations.dart';

class SessionTimerBar extends StatefulWidget {
  final Duration initialDuration;
  final ValueChanged<Duration>? onTick;
  final VoidCallback? onDone;
  final VoidCallback? onClose;

  const SessionTimerBar({
    super.key,
    required this.initialDuration,
    this.onTick,
    this.onDone,
    this.onClose,
  });

  @override
  State<SessionTimerBar> createState() => _SessionTimerBarState();
}

class _SessionTimerBarState extends State<SessionTimerBar>
    with SingleTickerProviderStateMixin {
  static const _durations = [60, 90, 120, 150, 180];
  late int _selectedIndex;
  late final SessionTimerController _controller;

  @override
  void initState() {
    super.initState();
    final initialSeconds = widget.initialDuration.inSeconds;
    _selectedIndex = _durations.indexOf(initialSeconds);
    if (_selectedIndex == -1) {
      _selectedIndex = _durations.indexOf(90);
    }
    _controller = SessionTimerController(
      total: Duration(seconds: _durations[_selectedIndex]),
      onTick: widget.onTick,
      onDone: () {
        SystemSound.play(SystemSoundType.click);
        HapticFeedback.mediumImpact();
        widget.onDone?.call();
      },
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final s = d.inSeconds.clamp(0, 359999);
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final r = (s % 60).toString().padLeft(2, '0');
    return '$m:$r';
  }

  void _changeDuration(int delta) {
    setState(() {
      _selectedIndex =
          (_selectedIndex + delta).clamp(0, _durations.length - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    return ValueListenableBuilder<Duration>(
      valueListenable: _controller.remaining,
      builder: (context, remaining, _) {
        final progress =
            1 - (remaining.inMilliseconds / _controller.total.inMilliseconds).clamp(0.0, 1.0);
        final textColor = Color.lerp(
          theme.colorScheme.onSurface,
          theme.colorScheme.onPrimary,
          progress,
        );
        return Semantics(
          label: loc.timerPauseLabel,
          value: _fmt(remaining),
          child: Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.hardEdge,
              child: Stack(
                children: [
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primaryContainer,
                            theme.colorScheme.primary,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        tooltip: loc.timerStart,
                        icon: const Icon(Icons.play_arrow),
                        onPressed: () => _controller.startWith(
                            Duration(seconds: _durations[_selectedIndex])),
                      ),
                      IconButton(
                        tooltip: loc.timerDecrease,
                        icon: const Icon(Icons.remove),
                        onPressed: () =>
                            _changeDuration(-1),
                      ),
                      Text(
                        '${_durations[_selectedIndex]} ${loc.secondsAbbreviation}',
                        style: theme.textTheme.titleMedium,
                      ),
                      IconButton(
                        tooltip: loc.timerIncrease,
                        icon: const Icon(Icons.add),
                        onPressed: () =>
                            _changeDuration(1),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            _fmt(remaining),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        icon: const Icon(Icons.close),
                        onPressed: widget.onClose,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

