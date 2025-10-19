import 'package:flutter/material.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/ui/timer/active_workout_timer.dart';

class TimerAppBarTitle extends StatelessWidget {
  final Widget title;
  final bool centerTitle;

  const TimerAppBarTitle({
    super.key,
    required this.title,
    this.centerTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasOutlineBranding = theme.extension<AppBrandTheme>() != null;
    final alignment = centerTitle ? Alignment.center : Alignment.centerLeft;
    final mainAxisAlignment =
        centerTitle ? MainAxisAlignment.center : MainAxisAlignment.start;

    if (!hasOutlineBranding) {
      return Align(
        alignment: alignment,
        child: title,
      );
    }

    if (!centerTitle) {
      return Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const ActiveWorkoutTimer(
            padding: EdgeInsets.only(right: 12, left: 4),
            compact: true,
          ),
          Expanded(
            child: Align(
              alignment: alignment,
              child: title,
            ),
          ),
        ],
      );
    }

    return SizedBox.expand(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.center,
            child: title,
          ),
          const Align(
            alignment: Alignment.centerLeft,
            child: ActiveWorkoutTimer(
              padding: EdgeInsets.only(right: 12, left: 4),
              compact: true,
            ),
          ),
        ],
      ),
    );
  }
}
