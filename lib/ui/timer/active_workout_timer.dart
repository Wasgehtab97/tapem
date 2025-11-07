import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/features/device/presentation/controllers/workout_day_controller.dart';
import 'package:tapem/core/services/workout_session_duration_service.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/utils/duration_format.dart';
import 'package:tapem/core/widgets/brand_outline.dart';

class ActiveWorkoutTimer extends StatelessWidget {
  final EdgeInsetsGeometry? padding;
  final bool compact;
  final String? sessionKey;

  const ActiveWorkoutTimer({
    super.key,
    this.padding,
    this.compact = false,
    this.sessionKey,
  });

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
            final colors = theme.colorScheme;
            final outlineColor = brand?.outline ?? colors.primary;
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
            final content = BrandOutline(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              radiusOverride: borderRadius,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: iconSize,
                    color: outlineColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    formatted,
                    style: baseTextStyle.copyWith(
                      color: outlineColor,
                      fontWeight: FontWeight.w600,
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
                  onTap: () async {
                    final key = sessionKey;
                    if (key != null) {
                      final controller =
                          Provider.maybeOf<WorkoutDayController>(context, listen: false);
                      controller?.focusSession(key);
                    }
                    final dialogResult = await service.confirmStop(
                      context,
                      sessionKey: key,
                    );
                    if (!context.mounted) return;
                    final resultKey = dialogResult.sessionKey;
                    if (resultKey != null && resultKey != key) {
                      final controller =
                          Provider.maybeOf<WorkoutDayController>(context, listen: false);
                      controller?.focusSession(resultKey);
                    }
                    if (dialogResult.result == StopResult.save) {
                      await service.save();
                    } else if (dialogResult.result == StopResult.discard) {
                      await service.discard();
                    } else if (dialogResult.result == StopResult.resume &&
                        dialogResult.resumeTarget != null) {
                      final target = dialogResult.resumeTarget!;
                      Navigator.of(context).pushNamed(
                        AppRouter.workoutDay,
                        arguments: {
                          'gymId': target.gymId,
                          'deviceId': target.deviceId,
                          'exerciseId': target.exerciseId ?? target.deviceId,
                        },
                      );
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
