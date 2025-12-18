import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/services/workout_session_duration_service.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/utils/duration_format.dart';
import 'package:tapem/core/widgets/brand_outline.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/features/device/providers/workout_day_controller_provider.dart';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRunning = ref
        .watch(workoutSessionDurationServiceProvider.select((s) => s.isRunning));
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
        final content = Container(
          padding: compact
              ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
              : const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: borderRadius,
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
            children: [
              Icon(
                Icons.timer_outlined,
                size: iconSize,
                color: Colors.white.withOpacity(0.9),
              ),
              const SizedBox(width: 8),
              Text(
                formatted,
                style: baseTextStyle.copyWith(
                  color: Colors.white.withOpacity(0.95),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
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
              onTap: () async {
                final key = sessionKey;
                if (key != null) {
                  final controller = ref.read(workoutDayControllerProvider);
                  controller.focusSession(key);
                }

                // Check if we are already on the workout screen
                final currentRoute = ModalRoute.of(context)?.settings.name;
                final isOnWorkoutScreen =
                    currentRoute == '/workout_day' || // AppRouter.workoutDay
                        currentRoute == '/device'; // AppRouter.device

                if (isOnWorkoutScreen) {
                  // Standard behavior: Confirm stop
                  final dialogResult = await service.confirmStop(
                    context,
                    sessionKey: key,
                  );
                  if (!context.mounted) return;
                  final resultKey = dialogResult.sessionKey;
                  if (resultKey != null && resultKey != key) {
                    final controller = ref.read(workoutDayControllerProvider);
                    controller.focusSession(resultKey);
                  }
                  if (dialogResult.result == StopResult.discard) {
                    await service.discard();
                  }
                  return;
                }

                // We are NOT on the workout screen.
                // Check if there are active sessions to navigate to.
                final controller = ref.read(workoutDayControllerProvider);
                final auth = ref.read(authControllerProvider);
                final userId = auth.userId;
                final gymId = auth.gymCode;

                final hasActiveSessions = (userId != null &&
                    gymId != null &&
                    controller
                        .sessionsFor(userId: userId, gymId: gymId)
                        .isNotEmpty);

                if (!hasActiveSessions) {
                  // No active sessions (maybe closed but timer running?)
                  // Just show stop dialog
                  final dialogResult = await service.confirmStop(
                    context,
                    sessionKey: key,
                  );
                  if (dialogResult.result == StopResult.discard) {
                    await service.discard();
                  }
                  return;
                }

                // Show options: Go to Workout OR Stop
                final loc = AppLocalizations.of(context)!;
                final action = await showModalBottomSheet<String>(
                  context: context,
                  builder: (ctx) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading:
                              Icon(Icons.fitness_center, color: outlineColor),
                          title: const Text('Zum Workout'), // TODO: Localize
                          onTap: () => Navigator.pop(ctx, 'goto'),
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.stop_circle_outlined,
                            color: Colors.red,
                          ),
                          title: Text(loc.sessionStopTitle),
                          textColor: Colors.red,
                          iconColor: Colors.red,
                          onTap: () => Navigator.pop(ctx, 'stop'),
                        ),
                      ],
                    ),
                  ),
                );

                if (!context.mounted) return;

                if (action == 'goto') {
                  // In den Home-Screen wechseln und den Workout-Tab aktivieren.
                  Navigator.of(context).pushNamed(
                    AppRouter.home,
                    arguments: 2,
                  );
                } else if (action == 'stop') {
                  final dialogResult = await service.confirmStop(
                    context,
                    sessionKey: key,
                  );
                  if (dialogResult.result == StopResult.discard) {
                    await service.discard();
                  }
                }
              },
              child: content,
            ),
          ),
        );
      },
    );
  }
}
