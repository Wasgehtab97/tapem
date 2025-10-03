import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/services/workout_session_duration_service.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/brand_on_colors.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/utils/duration_format.dart';

class ActiveWorkoutTimer extends StatelessWidget {
  final EdgeInsetsGeometry? padding;
  final bool compact;

  const ActiveWorkoutTimer({super.key, this.padding, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Selector<WorkoutSessionDurationService, bool>(
      selector: (_, service) => service.isRunning,
      builder: (context, isRunning, _) {
        if (!isRunning) {
          return const SizedBox.shrink();
        }
        final service = context.read<WorkoutSessionDurationService>();
        return StreamBuilder<Duration>(
          stream: service.tickStream,
          initialData: service.elapsed,
          builder: (context, snapshot) {
            final duration = snapshot.data ?? Duration.zero;
            final formatted = formatDurationHm(duration);
            final theme = Theme.of(context);
            final brand = theme.extension<AppBrandTheme>();
            final onColors = theme.extension<BrandOnColors>();
            final gradient = brand?.gradient;
            final colors = theme.colorScheme;
            final gradientColors = gradient?.colors ?? const <Color>[];
            final hasUsableGradient = gradientColors.isNotEmpty &&
                gradientColors.any((c) => c.computeLuminance() > 0.2);

            final isOutlineBrandTheme = brand != null && onColors != null;

            Color? backgroundColor;
            final LinearGradient? resolvedGradient;
            Color foregroundColor;

            final isBlackWhiteTheme =
                !hasUsableGradient &&
                    theme.colorScheme.background == Colors.black &&
                    theme.colorScheme.primary == Colors.white &&
                    (brand?.gradient.colors
                            .every((c) => c.computeLuminance() < 0.05) ??
                        false);

            if (isOutlineBrandTheme) {
              resolvedGradient = null;
              backgroundColor = null;
              foregroundColor = brand?.outline ?? onColors?.onGradient ??
                  colors.onSecondaryContainer;
            } else if (hasUsableGradient) {
              resolvedGradient = gradient;
              backgroundColor = null;
              foregroundColor = brand?.onBrand ?? colors.onSecondaryContainer;
            } else {
              resolvedGradient = null;
              final fallbackBackground = colors.primary;
              backgroundColor = fallbackBackground;
              foregroundColor = colors.onPrimary;

              final brightness = ThemeData.estimateBrightnessForColor(
                fallbackBackground,
              );
              if (isBlackWhiteTheme) {
                backgroundColor = Colors.white.withOpacity(0.12);
                foregroundColor = Colors.white;
              } else if (brightness == Brightness.dark &&
                  foregroundColor.computeLuminance() < 0.6) {
                foregroundColor = Colors.white;
              } else if (brightness == Brightness.light &&
                  foregroundColor.computeLuminance() > 0.6) {
                foregroundColor = Colors.black;
              }
            }

            final borderRadius = BorderRadius.circular(AppRadius.button);
            final iconSize = compact ? 16.0 : 18.0;
            final resolvedPadding = padding ??
                (compact
                    ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
                    : const EdgeInsets.symmetric(horizontal: 16));
            final baseTextStyle = (compact
                    ? theme.textTheme.titleSmall
                    : theme.textTheme.titleMedium) ??
                theme.textTheme.bodyMedium ??
                const TextStyle(fontSize: 14);
            final outlineRadius =
                (brand?.outlineRadius ?? borderRadius) as BorderRadius;
            final outlineWidth = brand?.outlineWidth ?? 2.0;
            final innerRadius = outlineRadius - BorderRadius.circular(outlineWidth);
            final outlineSurfaceColor = theme.appBarTheme.backgroundColor ??
                theme.colorScheme.surface;

            final chipBody = Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: iconSize,
                    color: foregroundColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    formatted,
                    style: baseTextStyle.copyWith(
                      color: foregroundColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );

            Widget content;
            if (isOutlineBrandTheme) {
              content = Container(
                decoration: BoxDecoration(
                  gradient: brand?.outlineGradient,
                  color: brand?.outlineGradient == null ? brand?.outline : null,
                  borderRadius: outlineRadius,
                ),
                child: Container(
                  margin: EdgeInsets.all(outlineWidth),
                  decoration: BoxDecoration(
                    color: outlineSurfaceColor,
                    borderRadius: innerRadius,
                    border: brand?.outlineGradient == null
                        ? Border.all(
                            color: brand?.outline ?? foregroundColor,
                            width: outlineWidth,
                          )
                        : null,
                  ),
                  child: chipBody,
                ),
              );
            } else {
              content = DecoratedBox(
                decoration: BoxDecoration(
                  gradient: resolvedGradient,
                  color: backgroundColor,
                  borderRadius: borderRadius,
                ),
                child: chipBody,
              );
            }

            return Padding(
              padding: resolvedPadding,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: borderRadius,
                  onTap: () async {
                    final result = await service.confirmStop(context);
                    if (!context.mounted) return;
                    if (result == StopResult.save) {
                      await service.save();
                    } else if (result == StopResult.discard) {
                      await service.discard();
                    }
                  },
                  child: content,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
