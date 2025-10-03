import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/l10n/app_localizations.dart';

import 'session_timer_controller.dart';

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
    final loc = AppLocalizations.of(context)!;
    final brand = theme.extension<AppBrandTheme>();
    final highContrast = MediaQuery.of(context).highContrast;

    return ValueListenableBuilder<Duration>(
      valueListenable: _controller.remaining,
      builder: (context, remaining, _) {
        final progress =
            1 - (remaining.inMilliseconds / _controller.total.inMilliseconds).clamp(0.0, 1.0);
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

