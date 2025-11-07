import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';
import 'package:provider/provider.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/features/device/domain/usecases/get_device_by_nfc_code.dart';
import 'package:tapem/features/device/presentation/models/workout_device_selection.dart';
import 'package:tapem/features/device/presentation/screens/exercise_list_screen.dart';
import 'package:tapem/services/membership_service.dart';
import 'package:tapem/l10n/app_localizations.dart';

class NfcScanButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final authProv = context.read<AuthProvider>();
    final getDeviceUC = context.read<GetDeviceByNfcCode>();
    final membership = context.read<MembershipService>();
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
                  final payload = records.first.payload.skip(3);
                  code = String.fromCharCodes(payload);
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

              await membership.ensureMembership(gymId, authProv.userId!);

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
                final selection = WorkoutDeviceSelection(
                  gymId: gymId,
                  deviceId: resolvedDeviceId,
                  exerciseId: resolvedExerciseId,
                );
                if (selectionHandler != null) {
                  await selectionHandler(selection);
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
