import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tapem/ui/timer/session_timer_service.dart';

class SessionRestTimer extends StatefulWidget {
  const SessionRestTimer({
    super.key,
    this.initialSeconds,
  });

  final int? initialSeconds;

  @override
  SessionRestTimerState createState() => SessionRestTimerState();
}

class SessionRestTimerState extends State<SessionRestTimer> {
  late final SessionTimerService _service;
  late final VoidCallback _doneListener;

  SessionTimerService get service => _service;

  @override
  void initState() {
    super.initState();
    _service = SessionTimerService(
      initialDuration: _initialDurationFrom(widget.initialSeconds),
    );
    _doneListener = () {
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.mediumImpact();
    };
    _service.addDoneListener(_doneListener);
  }

  @override
  void didUpdateWidget(covariant SessionRestTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSeconds != oldWidget.initialSeconds) {
      applyInitialSeconds(widget.initialSeconds);
    }
  }

  @override
  void dispose() {
    _service.removeDoneListener(_doneListener);
    _service.dispose();
    super.dispose();
  }

  void applyInitialSeconds(int? seconds) {
    final duration = _initialDurationFrom(seconds);
    if (duration != null) {
      _service.applyInitialDuration(duration);
    }
  }

  Duration? _initialDurationFrom(int? seconds) {
    if (seconds == null) {
      return null;
    }
    return Duration(seconds: seconds);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          width: 64,
          height: 64,
          child: ValueListenableBuilder<Duration>(
            valueListenable: _service.remaining,
            builder: (context, remaining, _) {
              final totalMillis = _service.total.inMilliseconds;
              final progress = totalMillis == 0
                  ? 0.0
                  : 1 -
                      (remaining.inMilliseconds / totalMillis)
                          .clamp(0.0, 1.0);
              final displaySeconds = remaining.inSeconds % 60;
              final displayMinutes = remaining.inMinutes;
              final timeLabel =
                  '${displayMinutes.toString().padLeft(2, '0')}:${displaySeconds.toString().padLeft(2, '0')}';
              return Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 4,
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Text(
                        timeLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ) ??
                            TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: _service.running,
                    builder: (context, isRunning, _) {
                      return Semantics(
                        button: true,
                        label: isRunning
                            ? 'Stop rest timer'
                            : 'Start rest timer',
                        child: IconButton(
                          iconSize: 22,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            isRunning ? Icons.stop : Icons.play_arrow,
                          ),
                          tooltip:
                              isRunning ? 'Stop rest timer' : 'Start rest timer',
                          onPressed: () {
                            if (isRunning) {
                              _service.stop();
                            } else {
                              _service.start();
                            }
                          },
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        _DurationSelector(service: _service),
      ],
    );
  }
}

class _DurationSelector extends StatelessWidget {
  const _DurationSelector({
    required this.service,
  });

  final SessionTimerService service;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final durations = service.availableDurations;
    return AnimatedBuilder(
      animation: service,
      builder: (context, _) {
        final selectedSeconds = service.selectedDuration.inSeconds;
        return PopupMenuButton<int>(
          tooltip: 'Select rest duration',
          onSelected: (seconds) {
            final index = durations.indexOf(seconds);
            if (index == -1) {
              return;
            }
            final delta = index - service.selectedIndex;
            if (delta != 0) {
              service.changeDuration(delta);
            }
          },
          itemBuilder: (context) {
            return [
              for (final seconds in durations)
                PopupMenuItem<int>(
                  value: seconds,
                  child: Text('${seconds}s'),
                ),
            ];
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${selectedSeconds}s',
              style: theme.textTheme.labelSmall,
            ),
          ),
        );
      },
    );
  }
}
