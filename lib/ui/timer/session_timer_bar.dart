import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'session_timer_controller.dart';

class SessionTimerBar extends StatefulWidget {
  final Duration total;
  final bool initiallyRunning;
  final bool muted;
  final ValueChanged<Duration>? onTick;
  final VoidCallback? onDone;
  final VoidCallback? onClose;
  final VoidCallback? onMuteToggle;

  const SessionTimerBar({
    super.key,
    required this.total,
    this.initiallyRunning = false,
    this.muted = false,
    this.onTick,
    this.onDone,
    this.onClose,
    this.onMuteToggle,
  });

  @override
  State<SessionTimerBar> createState() => _SessionTimerBarState();
}

class _SessionTimerBarState extends State<SessionTimerBar>
    with SingleTickerProviderStateMixin {
  late final SessionTimerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SessionTimerController(
      total: widget.total,
      initiallyRunning: widget.initiallyRunning,
      onTick: widget.onTick,
      onDone: () {
        if (!widget.muted) {
          SystemSound.play(SystemSoundType.click);
        }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<Duration>(
      valueListenable: _controller.remaining,
      builder: (context, remaining, _) {
        final progress =
            1 - (remaining.inMilliseconds / widget.total.inMilliseconds).clamp(0.0, 1.0);
        final textColor = Color.lerp(
          theme.colorScheme.onSurface,
          theme.colorScheme.onPrimary,
          progress,
        );
        return Semantics(
          label: 'Rest timer',
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
                      ValueListenableBuilder<bool>(
                        valueListenable: _controller.running,
                        builder: (context, running, _) => IconButton(
                          tooltip: running ? 'Pause' : 'Start',
                          icon:
                              Icon(running ? Icons.pause : Icons.play_arrow),
                          onPressed: running
                              ? _controller.pause
                              : _controller.resume,
                        ),
                      ),
                      IconButton(
                        tooltip: widget.muted ? 'Unmute' : 'Mute',
                        icon: Icon(
                            widget.muted ? Icons.volume_off : Icons.volume_up),
                        onPressed: widget.onMuteToggle,
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

