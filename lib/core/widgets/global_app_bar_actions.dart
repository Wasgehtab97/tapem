import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tapem/core/services/workout_session_duration_service.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/utils/duration_format.dart';
import 'package:tapem/features/nfc/widgets/nfc_scan_button.dart';

/// Builds a list of app bar actions that always appends the global
/// workout timer and NFC scan controls to the provided [leadingActions].
List<Widget> buildGlobalAppBarActions({
  List<Widget>? leadingActions,
  bool showNfcButton = true,
}) {
  return <Widget>[
    ...?leadingActions,
    GlobalAppBarActions(showNfcButton: showNfcButton),
  ];
}

/// Shared trailing action row that exposes the running workout timer and the
/// NFC scan shortcut.
class GlobalAppBarActions extends StatelessWidget {
  final bool showNfcButton;

  const GlobalAppBarActions({super.key, this.showNfcButton = true});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const WorkoutTimerChip(),
        if (showNfcButton) const SizedBox(width: 8),
        if (showNfcButton) const NfcScanButton(),
      ],
    );
  }
}

/// Compact chip that surfaces the currently running workout duration in the
/// global header. When no workout is active, the chip collapses.
class WorkoutTimerChip extends StatelessWidget {
  const WorkoutTimerChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutSessionDurationService>(
      builder: (context, service, _) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SizeTransition(
                axis: Axis.horizontal,
                axisAlignment: -1,
                sizeFactor: animation,
                child: child,
              ),
            );
          },
          child: service.isRunning
              ? _RunningTimerChip(
                  key: const ValueKey('workout-timer-active'),
                  service: service,
                )
              : const SizedBox.shrink(
                  key: ValueKey('workout-timer-idle'),
                ),
        );
      },
    );
  }
}

class _RunningTimerChip extends StatelessWidget {
  final WorkoutSessionDurationService service;

  const _RunningTimerChip({required this.service, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final brand = theme.extension<AppBrandTheme>();
    final textStyle = (brand?.textStyle ?? theme.textTheme.labelLarge)?.copyWith(
      color: brand?.onBrand ?? colors.onPrimary,
      fontFeatures: const [FontFeature.tabularFigures()],
      letterSpacing: 0.2,
    );

    final decoration = BoxDecoration(
      gradient: brand?.gradient,
      color: brand == null ? colors.secondaryContainer : null,
      borderRadius: BorderRadius.circular(AppRadius.button),
      boxShadow: brand?.shadow,
    );

    return StreamBuilder<Duration>(
      stream: service.tickStream,
      initialData: service.elapsed,
      builder: (context, snapshot) {
        final duration = snapshot.data ?? service.elapsed;
        final formatted = formatDurationHms(duration);
        final contentColor = textStyle?.color ?? colors.onSecondaryContainer;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: DecoratedBox(
            decoration: decoration,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 18,
                    color: contentColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    formatted,
                    style: textStyle,
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
