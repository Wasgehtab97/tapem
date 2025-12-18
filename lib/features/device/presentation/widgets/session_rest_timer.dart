
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
           BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
           ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: _service.running,
            builder: (context, isRunning, _) {
              return Semantics(
                button: true,
                label: isRunning ? 'Pause rest timer' : 'Start rest timer',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      widget.onInteraction?.call();
                      if (isRunning) {
                        _service.stop();
                      } else {
                        _service.start();
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        isRunning ? Icons.pause : Icons.play_arrow,
                        size: 18,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 2),
          Tooltip(
            message: 'Select rest duration',
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _handleTimerTap(context),
              child: SizedBox(
                 width: 38,
                 height: 38,
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
                          strokeWidth: 2.5,
                          backgroundColor: Colors.white.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                        Text(
                          timeLabel,
                          style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleTimerTap(BuildContext context) async {
    widget.onInteraction?.call();
    final durations = _service.availableDurations;
    final selectedDuration = _service.selectedDuration.inSeconds;
    final chosenSeconds = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.8),
      isScrollControlled: true,
      builder: (sheetContext) {
        final theme = Theme.of(context);
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF14171A).withOpacity(0.9),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 40,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Pausenzeit wählen', // localized later if needed, hardcode for now or use passed param
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Flexible(
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.8,
                      ),
                      itemCount: durations.length,
                      itemBuilder: (context, i) {
                        final seconds = durations[i];
                        final isSelected = seconds == selectedDuration;
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.of(sheetContext).pop(seconds),
                            borderRadius: BorderRadius.circular(16),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.blueAccent.withOpacity(0.2)
                                    : Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.blueAccent
                                      : Colors.white.withOpacity(0.1),
                                  width: isSelected ? 1.5 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: Colors.blueAccent.withOpacity(0.3),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        )
                                      ]
                                    : [],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${seconds}s',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: isSelected ? Colors.white : Colors.white70,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
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
