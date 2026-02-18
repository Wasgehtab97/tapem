import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/bootstrap/navigation.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/settings_provider.dart';
import 'package:tapem/core/services/workout_session_coordinator.dart';
import 'package:tapem/features/device/presentation/controllers/workout_day_controller.dart';
import 'package:tapem/features/device/presentation/workout_finish_flow.dart';
import 'package:tapem/features/device/presentation/workout_flow_error.dart';
import 'package:tapem/l10n/app_localizations.dart';

enum WorkoutManualStopAction { save, discard }

enum WorkoutManualStopStatus { cancelled, saved, discarded, failed }

typedef WorkoutSaveAndFinishInvoker =
    Future<WorkoutFinishResult> Function({
      required BuildContext context,
      required GlobalKey<NavigatorState> navigatorKey,
      required WorkoutDayController controller,
      required AuthProvider auth,
      required SettingsProvider settings,
      required List<WorkoutDaySession> sessions,
      required String fallbackGymId,
      required bool navigateToHomeProfileOnSuccess,
      ProviderContainer? container,
      String? planId,
      String? planName,
      String? sessionAnchorDayKey,
      DateTime? sessionAnchorStartTime,
    });

class WorkoutManualStopFlow {
  const WorkoutManualStopFlow._();

  static WorkoutSaveAndFinishInvoker _saveAndFinishInvoker =
      WorkoutFinishFlow.saveAndFinish;

  @visibleForTesting
  static void debugSetSaveAndFinishInvoker(WorkoutSaveAndFinishInvoker? value) {
    _saveAndFinishInvoker = value ?? WorkoutFinishFlow.saveAndFinish;
  }

  static Future<WorkoutManualStopStatus> run({
    required BuildContext context,
    required AuthProvider auth,
    required WorkoutDayController controller,
    required SettingsProvider settings,
    required WorkoutSessionCoordinator sessionCoordinator,
    required bool navigateToHomeProfileOnSuccess,
    ProviderContainer? container,
    GlobalKey<NavigatorState>? customNavigatorKey,
  }) async {
    final userId = auth.userId;
    final gymId = auth.gymCode;
    final loc = AppLocalizations.of(context)!;
    if (userId == null ||
        userId.isEmpty ||
        gymId == null ||
        gymId.isEmpty ||
        !context.mounted) {
      if (context.mounted) {
        final code = (userId == null || userId.isEmpty)
            ? WorkoutFlowErrorCode.missingUserContext
            : WorkoutFlowErrorCode.missingGymContext;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(workoutFlowErrorMessage(loc, code))),
        );
      }
      return WorkoutManualStopStatus.failed;
    }

    final sessions = controller.sessionsFor(userId: userId, gymId: gymId);
    final canSave = sessions.any((session) => session.canShowSaveAction);

    final action = await showDialog<WorkoutManualStopAction>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aktives Training'),
        content: Text(
          canSave
              ? 'Du kannst den Trainingstag jetzt speichern oder komplett verwerfen.'
              : 'Es gibt aktuell nichts zum Speichern. Du kannst den Trainingstag nur verwerfen oder zurückgehen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Zurück'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(ctx).pop(WorkoutManualStopAction.discard),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Verwerfen'),
          ),
          FilledButton(
            onPressed: canSave
                ? () => Navigator.of(ctx).pop(WorkoutManualStopAction.save)
                : null,
            child: const Text('Speichern'),
          ),
        ],
      ),
    );

    if (action == null || !context.mounted) {
      return WorkoutManualStopStatus.cancelled;
    }

    if (action == WorkoutManualStopAction.save) {
      return _saveAndFinalize(
        context: context,
        auth: auth,
        controller: controller,
        settings: settings,
        sessionCoordinator: sessionCoordinator,
        navigateToHomeProfileOnSuccess: navigateToHomeProfileOnSuccess,
        container: container,
        customNavigatorKey: customNavigatorKey,
        sessions: sessions,
      );
    }

    try {
      await sessionCoordinator.finishManuallyFromProfileStop();
      controller.cancelActivePlan(
        userId: userId,
        gymId: gymId,
        date: sessionCoordinator.anchorStartAt,
        dayKey: sessionCoordinator.anchorDayKey,
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              workoutFlowErrorMessage(loc, WorkoutFlowErrorCode.discardFailed),
            ),
          ),
        );
      }
      return WorkoutManualStopStatus.failed;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trainingstag wurde abgebrochen.')),
      );
    }
    return WorkoutManualStopStatus.discarded;
  }

  static Future<WorkoutManualStopStatus> saveFromWorkoutDay({
    required BuildContext context,
    required AuthProvider auth,
    required WorkoutDayController controller,
    required SettingsProvider settings,
    required WorkoutSessionCoordinator sessionCoordinator,
    ProviderContainer? container,
    GlobalKey<NavigatorState>? customNavigatorKey,
  }) async {
    final userId = auth.userId;
    final gymId = auth.gymCode;
    final loc = AppLocalizations.of(context)!;
    if (userId == null ||
        userId.isEmpty ||
        gymId == null ||
        gymId.isEmpty ||
        !context.mounted) {
      if (context.mounted) {
        final code = (userId == null || userId.isEmpty)
            ? WorkoutFlowErrorCode.missingUserContext
            : WorkoutFlowErrorCode.missingGymContext;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(workoutFlowErrorMessage(loc, code))),
        );
      }
      return WorkoutManualStopStatus.failed;
    }
    final sessions = controller.sessionsFor(userId: userId, gymId: gymId);
    return _saveAndFinalize(
      context: context,
      auth: auth,
      controller: controller,
      settings: settings,
      sessionCoordinator: sessionCoordinator,
      navigateToHomeProfileOnSuccess: true,
      container: container,
      customNavigatorKey: customNavigatorKey,
      sessions: sessions,
    );
  }

  static Future<WorkoutManualStopStatus> _saveAndFinalize({
    required BuildContext context,
    required AuthProvider auth,
    required WorkoutDayController controller,
    required SettingsProvider settings,
    required WorkoutSessionCoordinator sessionCoordinator,
    required bool navigateToHomeProfileOnSuccess,
    required List<WorkoutDaySession> sessions,
    ProviderContainer? container,
    GlobalKey<NavigatorState>? customNavigatorKey,
  }) async {
    final gymId = auth.gymCode;
    final loc = AppLocalizations.of(context)!;
    if (gymId == null || gymId.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              workoutFlowErrorMessage(
                loc,
                WorkoutFlowErrorCode.missingGymContext,
              ),
            ),
          ),
        );
      }
      return WorkoutManualStopStatus.failed;
    }
    final anchorStartAt = sessionCoordinator.anchorStartAt;
    final anchorDayKey = sessionCoordinator.anchorDayKey;
    final planContext = controller.getPlanContext(
      gymId: gymId,
      date: anchorStartAt,
      dayKey: anchorDayKey,
    );
    final finishResult = await _saveAndFinishInvoker(
      context: context,
      navigatorKey: customNavigatorKey ?? navigatorKey,
      controller: controller,
      auth: auth,
      settings: settings,
      sessions: sessions,
      fallbackGymId: gymId,
      navigateToHomeProfileOnSuccess: navigateToHomeProfileOnSuccess,
      container: container,
      planId: planContext?.$1,
      planName: planContext?.$2,
      sessionAnchorDayKey: anchorDayKey,
      sessionAnchorStartTime: anchorStartAt,
    );
    if (finishResult.status == WorkoutFinishStatus.failed) {
      return WorkoutManualStopStatus.failed;
    }
    if (finishResult.savedAny) {
      final activeCoordinator =
          container?.read(workoutSessionCoordinatorProvider) ??
          sessionCoordinator;
      final userId = auth.userId;
      final gymId = auth.gymCode;
      // Defensive guard: der Save-Pfad finalisiert normalerweise bereits im
      // Controller. Wir finalisieren hier idempotent erneut auf dem
      // UI-gebundenen Coordinator, damit der Profil-Button deterministisch
      // auf "Play" zurueckspringt.
      try {
        if (userId != null &&
            userId.isNotEmpty &&
            gymId != null &&
            gymId.isNotEmpty) {
          await activeCoordinator.setActiveContext(uid: userId, gymId: gymId);
        }
      } catch (_) {
        // Ignore context-sync failures; finalization is attempted regardless.
      }
      final needsFallbackFinalize = _needsManualSaveFallbackFinalize(
        activeCoordinator,
      );
      if (needsFallbackFinalize) {
        try {
          await activeCoordinator.finishManuallyFromWorkoutSave();
        } catch (_) {
          // Ignore; in diesem Pfad wurde bereits gespeichert.
        }
      }
    }
    return finishResult.savedAny
        ? WorkoutManualStopStatus.saved
        : WorkoutManualStopStatus.cancelled;
  }

  static bool _needsManualSaveFallbackFinalize(
    WorkoutSessionCoordinator coordinator,
  ) {
    try {
      if (coordinator.isRunning) {
        return true;
      }
      return coordinator.finalizeReason !=
          WorkoutFinalizeReason.manualSave.name;
    } catch (_) {
      // If coordinator state cannot be read (e.g. stale/disposed mocks),
      // keep the old safe behavior and attempt an idempotent finalize.
      return true;
    }
  }
}
