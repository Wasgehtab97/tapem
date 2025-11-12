import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tapem/ui/timer/session_timer_service.dart';

class SessionRestTimer extends StatefulWidget {
  const SessionRestTimer({
    super.key,
    this.initialSeconds,
    this.onInteraction,
  });

  final int? initialSeconds;
  final VoidCallback? onInteraction;

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

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 40,
          height: 40,
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
              final textStyle =
                  theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontFeatures: const [
                          FontFeature.tabularFigures(),
                        ],
                      ) ??
                      TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      );
              return Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 3,
                  ),
                  Text(
                    timeLabel,
                    style: textStyle,
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        ValueListenableBuilder<bool>(
          valueListenable: _service.running,
          builder: (context, isRunning, _) {
            return Semantics(
              button: true,
              label:
                  isRunning ? 'Pause rest timer' : 'Start rest timer',
              child: IconButton(
                iconSize: 22,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                icon: Icon(isRunning ? Icons.pause : Icons.play_arrow),
                tooltip:
                    isRunning ? 'Pause rest timer' : 'Start rest timer',
                onPressed: () {
                  widget.onInteraction?.call();
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
        const SizedBox(width: 8),
        _DurationSelector(
          service: _service,
          onInteraction: widget.onInteraction,
        ),
      ],
    );
  }
}

class _DurationSelector extends StatelessWidget {
  const _DurationSelector({
    required this.service,
    this.onInteraction,
  });

  final SessionTimerService service;
  final VoidCallback? onInteraction;

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
          onOpened: onInteraction,
          onSelected: (seconds) {
            final index = durations.indexOf(seconds);
            if (index == -1) {
              return;
            }
            final delta = index - service.selectedIndex;
            if (delta != 0) {
              onInteraction?.call();
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
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            height: 32,
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
