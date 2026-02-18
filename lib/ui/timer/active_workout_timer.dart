import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/core/services/workout_session_duration_service.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/utils/duration_format.dart';
import 'package:tapem/ui/timer/active_workout_timer_style_provider.dart';

class ActiveWorkoutTimer extends ConsumerWidget {
  final EdgeInsetsGeometry? padding;
  final bool compact;
  final String? sessionKey;

  const ActiveWorkoutTimer({
    super.key,
    this.padding,
    this.compact = false,
    this.sessionKey,
  });

  Future<void> _showStylePicker(
    BuildContext context,
    WidgetRef ref,
    ActiveWorkoutTimerStyle currentStyle,
  ) async {
    final selected = await showModalBottomSheet<ActiveWorkoutTimerStyle>(
      context: context,
      backgroundColor: const Color(0xFF060A12),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final styles = ActiveWorkoutTimerStyle.values;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Timer-Design',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Wähle deinen Look für aktive Workouts',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.66),
                  ),
                ),
                const SizedBox(height: 14),
                for (final style in styles)
                  _TimerStyleOptionTile(
                    style: style,
                    isSelected: style == currentStyle,
                    compact: compact,
                    onTap: () => Navigator.of(sheetContext).pop(style),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null || selected == currentStyle) return;
    await ref.read(activeWorkoutTimerStyleProvider.notifier).setStyle(selected);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRunning = ref.watch(
      workoutSessionDurationServiceProvider.select((s) => s.isRunning),
    );
    if (!isRunning) {
      return const SizedBox.shrink();
    }
    final service = ref.read(workoutSessionDurationServiceProvider);

    return StreamBuilder<Duration>(
      stream: service.tickStream,
      initialData: service.elapsed,
      builder: (context, snapshot) {
        final duration = snapshot.data ?? Duration.zero;
        final formatted = formatDurationHm(duration);
        final theme = Theme.of(context);
        final brand = theme.extension<AppBrandTheme>();
        final colors = theme.colorScheme;
        final timerStyle = ref.watch(activeWorkoutTimerStyleProvider);
        final styleTokens = _timerStyleTokens(
          style: timerStyle,
          colors: colors,
          brand: brand,
        );
        final borderRadius = BorderRadius.circular(AppRadius.button);
        final iconSize = compact ? 16.0 : 18.0;
        final resolvedPadding =
            padding ??
            (compact
                ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
                : const EdgeInsets.symmetric(horizontal: 16));
        final baseTextStyle =
            (compact
                ? theme.textTheme.titleSmall
                : theme.textTheme.titleMedium) ??
            theme.textTheme.bodyMedium ??
            const TextStyle(fontSize: 14);
        final content = Container(
          padding: compact
              ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
              : const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: styleTokens.gradient,
            borderRadius: borderRadius,
            border: Border.all(color: Colors.transparent, width: 1),
            boxShadow: styleTokens.shadows,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer_outlined,
                size: iconSize,
                color: styleTokens.icon,
              ),
              const SizedBox(width: 8),
              Container(
                width: 1,
                height: compact ? 14 : 16,
                color: styleTokens.divider,
              ),
              const SizedBox(width: 8),
              Text(
                formatted,
                style: baseTextStyle.copyWith(
                  color: styleTokens.text,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.55,
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        );

        return Padding(
          padding: resolvedPadding,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: borderRadius,
              onTap: () => _showStylePicker(context, ref, timerStyle),
              child: content,
            ),
          ),
        );
      },
    );
  }
}

class _TimerStyleTokens {
  const _TimerStyleTokens({
    required this.gradient,
    required this.shadows,
    required this.icon,
    required this.text,
    required this.divider,
  });

  final Gradient gradient;
  final List<BoxShadow> shadows;
  final Color icon;
  final Color text;
  final Color divider;
}

_TimerStyleTokens _timerStyleTokens({
  required ActiveWorkoutTimerStyle style,
  required ColorScheme colors,
  required AppBrandTheme? brand,
}) {
  final accent = brand?.outline ?? colors.secondary;
  switch (style) {
    case ActiveWorkoutTimerStyle.glass:
      return _TimerStyleTokens(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF101A2A).withOpacity(0.76),
            const Color(0xFF0C2530).withOpacity(0.58),
          ],
        ),
        shadows: const [],
        icon: Colors.white.withOpacity(0.95),
        text: Colors.white.withOpacity(0.96),
        divider: Colors.white.withOpacity(0.20),
      );
    case ActiveWorkoutTimerStyle.neon:
      return _TimerStyleTokens(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0D2027).withOpacity(0.80),
            accent.withOpacity(0.36),
          ],
        ),
        shadows: const [],
        icon: Colors.white.withOpacity(0.98),
        text: Colors.white.withOpacity(0.98),
        divider: accent.withOpacity(0.48),
      );
    case ActiveWorkoutTimerStyle.stealth:
      return _TimerStyleTokens(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.62),
            const Color(0xFF0A0A0A).withOpacity(0.48),
          ],
        ),
        shadows: const [],
        icon: Colors.white.withOpacity(0.90),
        text: Colors.white.withOpacity(0.92),
        divider: Colors.white.withOpacity(0.16),
      );
  }
}

class _TimerStyleOptionTile extends StatelessWidget {
  const _TimerStyleOptionTile({
    required this.style,
    required this.isSelected,
    required this.compact,
    required this.onTap,
  });

  final ActiveWorkoutTimerStyle style;
  final bool isSelected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final brand = theme.extension<AppBrandTheme>();
    final tokens = _timerStyleTokens(
      style: style,
      colors: colors,
      brand: brand,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? (brand?.outline ?? colors.secondary).withOpacity(0.6)
                    : Colors.white.withOpacity(0.10),
              ),
            ),
            child: Row(
              children: [
                _TimerStylePreview(tokens: tokens, compact: compact),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _styleLabel(style),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.95),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: isSelected
                      ? (brand?.outline ?? colors.secondary)
                      : Colors.white.withOpacity(0.45),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _styleLabel(ActiveWorkoutTimerStyle style) {
    switch (style) {
      case ActiveWorkoutTimerStyle.glass:
        return 'Glass';
      case ActiveWorkoutTimerStyle.neon:
        return 'Neon Pulse';
      case ActiveWorkoutTimerStyle.stealth:
        return 'Stealth';
    }
  }
}

class _TimerStylePreview extends StatelessWidget {
  const _TimerStylePreview({required this.tokens, required this.compact});

  final _TimerStyleTokens tokens;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 5)
          : const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: tokens.gradient,
        borderRadius: BorderRadius.circular(10),
        boxShadow: tokens.shadows,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 14, color: tokens.icon),
          const SizedBox(width: 6),
          Container(width: 1, height: 10, color: tokens.divider),
          const SizedBox(width: 6),
          Text(
            '00:42',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: tokens.text,
              fontWeight: FontWeight.w700,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
