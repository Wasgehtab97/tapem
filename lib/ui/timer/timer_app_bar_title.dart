import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/core/services/workout_session_duration_service.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/ui/timer/active_workout_timer.dart';

class TimerAppBarTitle extends ConsumerWidget {
  final Widget title;
  final bool centerTitle;

  const TimerAppBarTitle({
    super.key,
    required this.title,
    this.centerTitle = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hasOutlineBranding = theme.extension<AppBrandTheme>() != null;
    final alignment = centerTitle ? Alignment.center : Alignment.centerLeft;

    if (!hasOutlineBranding) {
      return Align(alignment: alignment, child: title);
    }

    const timerPadding = EdgeInsets.symmetric(horizontal: 6, vertical: 4);
    final timerIsRunning = ref.watch(
      workoutSessionDurationServiceProvider.select(
        (service) => service.isRunning,
      ),
    );
    final timerSlotWidth = timerIsRunning
        ? _estimatedTimerSlotWidth(context, theme)
        : 0.0;
    const timer = ActiveWorkoutTimer(padding: timerPadding, compact: true);

    if (!centerTitle) {
      return SizedBox(
        height: kToolbarHeight,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: timerSlotWidth,
              child: Align(alignment: Alignment.centerLeft, child: timer),
            ),
            Expanded(
              child: Align(alignment: alignment, child: title),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: kToolbarHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: timerSlotWidth,
              child: Align(alignment: Alignment.centerLeft, child: timer),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: timerSlotWidth),
            child: Align(alignment: Alignment.center, child: title),
          ),
        ],
      ),
    );
  }
}

double _estimatedTimerSlotWidth(BuildContext context, ThemeData theme) {
  final baseStyle =
      (theme.textTheme.titleSmall ??
              theme.textTheme.bodyMedium ??
              const TextStyle(fontSize: 14))
          .copyWith(fontWeight: FontWeight.w600);
  final painter = TextPainter(
    text: TextSpan(text: '000:00', style: baseStyle),
    maxLines: 1,
    textDirection: Directionality.of(context),
  )..layout();

  const iconWidth = 16.0;
  const spacing = 6.0;
  const outlinePadding = 12.0 * 2;
  const outerPadding = 6.0 * 2;

  return painter.width + iconWidth + spacing + outlinePadding + outerPadding;
}
