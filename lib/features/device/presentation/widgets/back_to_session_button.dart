import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/device_provider.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/l10n/app_localizations.dart';

class BackToSessionButton extends StatelessWidget {
  const BackToSessionButton({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.select<DeviceProvider, _BackToSessionData?>(
      (prov) {
        if (!prov.hasActiveUnsavedSession) return null;
        final gymId = prov.activeSessionGymId;
        final deviceId = prov.activeSessionDeviceId;
        final exerciseId = prov.activeSessionExerciseId;
        if (gymId == null || deviceId == null || exerciseId == null) {
          return null;
        }
        return _BackToSessionData(
          gymId: gymId,
          deviceId: deviceId,
          exerciseId: exerciseId,
        );
      },
    );

    final theme = Theme.of(context);
    final accentColor =
        theme.extension<AppBrandTheme>()?.outline ?? theme.colorScheme.secondary;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) => SizeTransition(
        sizeFactor: animation,
        axis: Axis.horizontal,
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: data == null
          ? const SizedBox.shrink()
          : Padding(
              key: const ValueKey('backToSessionButton'),
              padding: const EdgeInsets.only(right: 4),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  foregroundColor: accentColor,
                  side: BorderSide(color: accentColor.withOpacity(0.6)),
                  textStyle: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                icon: const Icon(Icons.restore, size: 18),
                label: Text(AppLocalizations.of(context)!.resumeSessionButton),
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    AppRouter.device,
                    arguments: {
                      'gymId': data.gymId,
                      'deviceId': data.deviceId,
                      'exerciseId': data.exerciseId,
                    },
                  );
                },
              ),
            ),
    );
  }
}

class _BackToSessionData {
  final String gymId;
  final String deviceId;
  final String exerciseId;

  const _BackToSessionData({
    required this.gymId,
    required this.deviceId,
    required this.exerciseId,
  });
}
