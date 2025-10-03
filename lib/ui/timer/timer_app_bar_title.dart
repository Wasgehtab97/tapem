import 'package:flutter/material.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/brand_on_colors.dart';
import 'package:tapem/ui/timer/active_workout_timer.dart';

class TimerAppBarTitle extends StatelessWidget {
  final Widget title;
  final bool centerTitle;
  final bool? showTimer;

  const TimerAppBarTitle({
    super.key,
    required this.title,
    this.centerTitle = true,
    this.showTimer,
  });

  @override
  Widget build(BuildContext context) {
    final alignment = centerTitle ? Alignment.center : Alignment.centerLeft;
    final mainAxisAlignment =
        centerTitle ? MainAxisAlignment.center : MainAxisAlignment.start;
    final shouldShowTimer = showTimer ?? _isOutlineBrandingTheme(context);

    if (!shouldShowTimer) {
      return Align(
        alignment: alignment,
        child: title,
      );
    }

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

bool _isOutlineBrandingTheme(BuildContext context) {
  final theme = Theme.of(context);
  final brand = theme.extension<AppBrandTheme>();
  final onColors = theme.extension<BrandOnColors>();
  return brand != null && onColors != null;
}
