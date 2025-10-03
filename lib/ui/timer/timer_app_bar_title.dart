import 'package:flutter/material.dart';
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
    final alignment = centerTitle ? Alignment.center : Alignment.centerLeft;
    final mainAxisAlignment =
        centerTitle ? MainAxisAlignment.center : MainAxisAlignment.start;

    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const ActiveWorkoutTimer(
          padding: EdgeInsets.only(right: 12),
          compact: true,
        ),
        Flexible(
          child: Align(
            alignment: alignment,
            child: title,
          ),
        ),
      ],
    );
  }
}
