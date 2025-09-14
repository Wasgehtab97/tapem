import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/features/device/presentation/providers/cardio_timer_provider.dart';
import 'package:tapem/core/util/duration_utils.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/core/logging/elog.dart';
import 'package:tapem/core/providers/device_provider.dart';

/// UI for cardio devices: large timer and play/pause button.
class CardioRunner extends StatelessWidget {
  final VoidCallback onCancel;
  final ValueChanged<int> onSave;

  const CardioRunner({
    super.key,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Consumer<CardioTimerProvider>(
      builder: (context, timer, _) {
        final time = formatHms(timer.elapsedSec);
        final theme = Theme.of(context);
        return Column(
          children: [
            const SizedBox(height: 24),
            Semantics(
              label: loc.cardioTotalTimeLabel,
              child: Text(
                time,
                style: theme.textTheme.displaySmall,
              ),
            ),
            const Spacer(),
            Semantics(
              label: timer.isRunning
                  ? loc.cardioPauseButtonLabel
                  : loc.cardioPlayButtonLabel,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(32),
                ),
                onPressed: () {
                  if (timer.isRunning) {
                    timer.pause();
                    elogUi('cardio_timer_paused', {
                      'elapsedSec': timer.elapsedSec,
                    });
                  } else {
                    timer.start();
                    final deviceId =
                        context.read<DeviceProvider>().device?.uid;
                    elogUi('cardio_timer_started', {
                      'deviceId': deviceId,
                    });
                  }
                },
                child: Icon(
                  timer.isRunning ? Icons.pause : Icons.play_arrow,
                  size: 48,
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: onCancel,
                    child: Text(loc.cancelButton),
                  ),
                  ElevatedButton(
                    onPressed: timer.isStopped && timer.elapsedSec > 0
                        ? () => onSave(timer.elapsedSec)
                        : null,
                    child: Text(loc.saveButton),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
