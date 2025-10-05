import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/l10n/app_localizations.dart';

import '../../core/audio/timer_chime_player.dart';
import 'session_timer_chime_coordinator.dart';
import 'session_timer_service.dart';

class SessionTimerBar extends StatefulWidget {
  final Duration initialDuration;
  final ValueChanged<Duration>? onTick;
  final VoidCallback? onDone;

  const SessionTimerBar({
    super.key,
    required this.initialDuration,
    this.onTick,
    this.onDone,
  });

  @override
  State<SessionTimerBar> createState() => _SessionTimerBarState();
}

class _SessionTimerBarState extends State<SessionTimerBar> {
  late final ValueChanged<Duration> _tickListener;
  late final VoidCallback _doneListener;
  late final TimerChimePlayer _chimePlayer;
  late final SessionTimerChimeCoordinator _chimeCoordinator;
  SessionTimerService? _service;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _chimePlayer = TimerChimePlayer();
    _chimeCoordinator = SessionTimerChimeCoordinator(player: _chimePlayer);
    _tickListener = (duration) {
      widget.onTick?.call(duration);
    };
    _doneListener = () {
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.mediumImpact();
      unawaited(_handleTimerCompletion());
    };
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextService = context.read<SessionTimerService>();
    if (!identical(_service, nextService)) {
      _chimeCoordinator.onTimerPauseOrStop();
      _service?.removeTickListener(_tickListener);
      _service?.removeDoneListener(_doneListener);
      _service?.running.removeListener(_handleRunningChange);
      _service = nextService;
      _service!.addTickListener(_tickListener);
      _service!.addDoneListener(_doneListener);
      _service!.applyInitialDuration(widget.initialDuration);
      _service!.running.addListener(_handleRunningChange);
      final currentlyRunning = _service!.running.value;
      _running = !currentlyRunning;
      _handleRunningChange();
    }
  }

  @override
  void dispose() {
    _service?.removeTickListener(_tickListener);
    _service?.removeDoneListener(_doneListener);
    _service?.running.removeListener(_handleRunningChange);
    _chimeCoordinator.onTimerPauseOrStop();
    unawaited(_chimePlayer.dispose());
    super.dispose();
  }

  void _handleRunningChange() {
    final service = _service;
    if (service == null) return;
    final isRunning = service.running.value;
    if (isRunning == _running) return;
    _running = isRunning;
    if (isRunning) {
      unawaited(
        _chimeCoordinator.onTimerStart(
          total: service.total,
          remaining: service.remaining.value,
        ),
      );
    } else {
      if (service.remaining.value > Duration.zero) {
        _chimeCoordinator.onTimerPauseOrStop();
      }
    }
  }

  Future<void> _handleTimerCompletion() async {
    await _chimeCoordinator.onTimerEnd(onNavigate: () async {
      widget.onDone?.call();
    });
  }

  String _fmt(Duration d) {
    final s = d.inSeconds.clamp(0, 359999);
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final r = (s % 60).toString().padLeft(2, '0');
    return '$m:$r';
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SessionTimerService>();
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final brand = theme.extension<AppBrandTheme>();
    final highContrast = MediaQuery.of(context).highContrast;

    return ValueListenableBuilder<Duration>(
      valueListenable: service.remaining,
      builder: (context, remaining, _) {
        final totalMillis = service.total.inMilliseconds;
        final progress = totalMillis <= 0
            ? 0.0
            : 1 - (remaining.inMilliseconds / totalMillis).clamp(0.0, 1.0);
        Color? textColor = Color.lerp(
          theme.colorScheme.onSurface,
          theme.colorScheme.onPrimary,
          progress,
        );

        final isBlackWhiteTheme =
            theme.colorScheme.background == Colors.black &&
                theme.colorScheme.primary == Colors.white &&
                theme.colorScheme.onPrimary == Colors.black;

        if (isBlackWhiteTheme) {
          textColor = Colors.white;
        }

        final backgroundColor = isBlackWhiteTheme
            ? Colors.black
            : theme.colorScheme.surfaceVariant;
        final borderColor = isBlackWhiteTheme
            ? Colors.white.withOpacity(0.24)
            : Colors.transparent;
        final progressDecoration = BoxDecoration(
          gradient: highContrast
              ? null
              : isBlackWhiteTheme
                  ? LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.45),
                        Colors.white,
                      ],
                    )
                  : brand?.gradient ??
                      LinearGradient(
                        colors: [
                          theme.colorScheme.primaryContainer,
                          theme.colorScheme.primary,
                        ],
                      ),
          color: highContrast
              ? brand?.outlineColorFallback ?? theme.colorScheme.primary
              : null,
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
                color: backgroundColor,
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.hardEdge,
              child: Stack(
                children: [
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      decoration: progressDecoration,
                    ),
                  ),
                  Row(
                    children: [
                      ValueListenableBuilder<bool>(
                        valueListenable: service.running,
                        builder: (context, running, _) {
                          return IconButton(
                            tooltip: running ? loc.timerStop : loc.timerStart,
                            icon: Icon(running ? Icons.stop : Icons.play_arrow),
                            onPressed: () {
                              if (running) {
                                service.stop();
                                _chimeCoordinator.onTimerPauseOrStop();
                              } else {
                                service.startWith(service.selectedDuration);
                              }
                            },
                          );
                        },
                      ),
                      IconButton(
                        tooltip: loc.timerDecrease,
                        icon: const Icon(Icons.remove),
                        onPressed: () =>
                            service.changeDuration(-1),
                      ),
                      Text(
                        '${service.selectedDuration.inSeconds} ${loc.secondsAbbreviation}',
                        style: theme.textTheme.titleMedium,
                      ),
                      IconButton(
                        tooltip: loc.timerIncrease,
                        icon: const Icon(Icons.add),
                        onPressed: () =>
                            service.changeDuration(1),
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
                      const SizedBox(width: 8),
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

