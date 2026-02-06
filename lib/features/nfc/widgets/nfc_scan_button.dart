import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/features/nfc/data/nfc_service.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/features/device/domain/usecases/get_device_by_nfc_code.dart';
import 'package:tapem/features/device/presentation/models/workout_device_selection.dart';
import 'package:tapem/features/device/presentation/screens/exercise_list_screen.dart';
import 'package:tapem/services/membership_service.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/core/services/workout_session_duration_service.dart';
import 'package:tapem/features/device/providers/workout_day_controller_provider.dart';
import 'package:tapem/features/device/providers/device_riverpod.dart';
import 'package:tapem/features/nfc/providers/nfc_providers.dart';
import 'package:tapem/features/nfc_stats/providers/nfc_scan_stats_providers.dart';
import 'package:tapem/core/analytics/analytics_service.dart';

class NfcScanButton extends ConsumerWidget {
  const NfcScanButton({
    super.key,
    this.deviceId,
    this.exerciseId,
    this.onBeforeOpen,
    this.onSelection,
  });

  final String? deviceId;
  final String? exerciseId;
  final VoidCallback? onBeforeOpen;
  final Future<void> Function(WorkoutDeviceSelection selection)? onSelection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authProv = ref.read(authControllerProvider);
    final getDeviceUC = ref.read(getDeviceByNfcCodeProvider);
    final membership = ref.read(membershipServiceProvider);
    final loc = AppLocalizations.of(context)!;

    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return IconButton(
      icon: const Icon(Icons.nfc),
      style: IconButton.styleFrom(
        backgroundColor: colors.secondary.withOpacity(0.15),
        foregroundColor: colors.secondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
      ),
      onPressed: () async {
        onBeforeOpen?.call();
        // Alte Session beenden (falls offen)
        try {
          await NfcManager.instance.stopSession();
        } catch (_) {}
        // Neue Session starten
        try {
          await NfcManager.instance.startSession(
            pollingOptions: {NfcPollingOption.iso14443},
            onDiscovered: (tag) async {
              String code = '';
              try {
                final ndef = Ndef.from(tag);
                final records = ndef?.cachedMessage?.records;
                if (records != null && records.isNotEmpty) {
                  code = NfcService.parseTextRecord(records.first);
                }
              } catch (_) {
                code = '';
              } finally {
                await NfcManager.instance.stopSession();
              }

              if (code.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loc.nfcNoCode)),
                );
                return;
              }

              final gymId = authProv.gymCode;
              if (gymId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loc.nfcNoGymSelected)),
                );
                return;
              }

              final dev = await getDeviceUC.execute(gymId, code);
              if (dev == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loc.deviceNotFound)),
                );
                return;
              }

              final userId = authProv.userId;
              if (userId != null) {
                await membership.ensureMembership(gymId, userId);
              }
              if (userId != null) {
                // Jede erfolgreiche NFC-Erkennung zählen (profilweit, gym-agnostisch).
                try {
                  final statsService = ref.read(nfcScanStatsServiceProvider);
                  await statsService.recordScan(
                    userId: userId,
                    gymId: gymId,
                    deviceId: dev.uid,
                    exerciseId: dev.isMulti ? null : dev.uid,
                  );
                  unawaited(AnalyticsService.logWorkoutNfcScan(
                    userId: userId,
                    gymId: gymId,
                    deviceId: dev.uid,
                    isMulti: dev.isMulti,
                    status: 'success',
                  ));
                } catch (_) {
                  // Telemetrie darf den Flow nicht blockieren.
                }
              }

              // Navigation basierend auf dev.isMulti
              final resolvedDeviceId = deviceId ?? dev.uid;
              final resolvedExerciseId = exerciseId ?? dev.uid;
              final selectionHandler = onSelection;

              if (dev.isMulti) {
                if (selectionHandler != null) {
                  final selection = await Navigator.of(context)
                      .push<WorkoutDeviceSelection>(
                    MaterialPageRoute(
                      builder: (ctx) => ExerciseListScreen(
                        gymId: gymId,
                        deviceId: resolvedDeviceId,
                        onSelect: (result) => Navigator.of(ctx).pop(result),
                      ),
                    ),
                  );
                  if (selection != null) {
                    await selectionHandler(selection);
                  }
                } else {
                  Navigator.of(context).pushNamed(
                    AppRouter.exerciseList,
                    arguments: {
                      'gymId': gymId,
                      'deviceId': resolvedDeviceId,
                    },
                  );
                }
              } else {
                if (userId != null) {
                  final controller = ref.read(workoutDayControllerProvider);
                  controller.addOrFocusSession(
                    gymId: gymId,
                    deviceId: resolvedDeviceId,
                    exerciseId: resolvedExerciseId,
                    exerciseName: dev.name,
                    userId: userId,
                  );

                  // LUX: Physical feedback
                  HapticFeedback.mediumImpact();

                  // LUX: Auto-Start Timer
                  final timer = ref.read(workoutSessionDurationServiceProvider);
                  if (!timer.isRunning) {
                    await timer.start(uid: userId, gymId: gymId);
                  }

                  // LUX: Visual confirmation
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Übung "${dev.name}" wurde hinzugefügt'),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }

                final selection = WorkoutDeviceSelection(
                  gymId: gymId,
                  deviceId: resolvedDeviceId,
                  exerciseId: resolvedExerciseId,
                  exerciseName: dev.name,
                );

                if (selectionHandler != null) {
                  await selectionHandler(selection);
                } else {
                  final timer = ref.read(workoutSessionDurationServiceProvider);
                  if (timer.isRunning) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRouter.home,
                      (route) => false,
                      arguments: 2,
                    );
                  } else {
                    Navigator.of(context).pushNamed(
                      AppRouter.workoutDay,
                      arguments: {
                        'gymId': gymId,
                        'deviceId': resolvedDeviceId,
                        'exerciseId': resolvedExerciseId,
                      },
                    );
                  }
                }
              }
            },
          );
        } catch (error) {
          // Session bei Fehler beenden
          try {
            await NfcManager.instance.stopSession();
          } catch (_) {}
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(loc.nfcError(error.toString()))));
        }
      },
    );
  }
}
