
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
        ValueListenableBuilder<bool>(
          valueListenable: _service.running,
          builder: (context, isRunning, _) {
            return Semantics(
              button: true,
              label:
                  isRunning ? 'Pause rest timer' : 'Start rest timer',
              child: IconButton(
                iconSize: 16,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 24,
                  minHeight: 24,
                ),
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
        const SizedBox(width: 4),
        Tooltip(
          message: 'Select rest duration',
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _handleTimerTap(context),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: SizedBox(
                width: 36,
                height: 36,
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
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ) ??
                            TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            );
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 2.5,
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
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleTimerTap(BuildContext context) async {
    widget.onInteraction?.call();
    final durations = _service.availableDurations;
    final selectedDuration = _service.selectedDuration.inSeconds;
    final chosenSeconds = await showModalBottomSheet<int>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Select rest duration',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              for (final seconds in durations)
                ListTile(
                  title: Text('${seconds}s'),
                  trailing: seconds == selectedDuration
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () {
                    Navigator.of(sheetContext).pop(seconds);
                  },
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );

    if (!mounted || chosenSeconds == null) {
      return;
    }
    final index = durations.indexOf(chosenSeconds);
    if (index == -1) {
      return;
    }
    final delta = index - _service.selectedIndex;
    if (delta != 0) {
      widget.onInteraction?.call();
      _service.changeDuration(delta);
    }
  }
}
