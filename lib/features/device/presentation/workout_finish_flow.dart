import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/settings_provider.dart';
import 'package:tapem/core/time/logic_day.dart';
import 'package:tapem/features/device/presentation/controllers/workout_day_controller.dart';
import 'package:tapem/features/story_session/presentation/widgets/training_done_overlay.dart';
import 'package:tapem/features/training_details/data/session_meta_source.dart';
import 'package:tapem/features/training_plan/application/training_plan_provider.dart';
import 'package:tapem/features/training_plan/data/sources/firestore_training_plan_source.dart';
import 'package:tapem/l10n/app_localizations.dart';

enum WorkoutFinishStatus { cancelled, completed, failed }

class WorkoutFinishResult {
  const WorkoutFinishResult({
    required this.status,
    this.saveResult,
    this.activeGymId,
  });

  final WorkoutFinishStatus status;
  final SaveAllSessionsResult? saveResult;
  final String? activeGymId;

  bool get savedAny => (saveResult?.saved ?? 0) > 0;
}

class WorkoutFinishFlow {
  const WorkoutFinishFlow._();

  static Future<WorkoutFinishResult> saveAndFinish({
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
  }) async {
    final loc = AppLocalizations.of(context)!;
    final userId = auth.userId;
    if (userId == null || userId.isEmpty) {
      return const WorkoutFinishResult(status: WorkoutFinishStatus.failed);
    }

    final confirmFinish = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Trainingstag abschließen?'),
        content: const Text(
          'Möchtest du alle offenen Sessions speichern und den Trainingstag beenden?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(loc.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(loc.saveButton),
          ),
        ],
      ),
    );

    if (!context.mounted || confirmFinish != true) {
      return const WorkoutFinishResult(status: WorkoutFinishStatus.cancelled);
    }

    final sessionsByKey = <String, WorkoutDaySession>{
      for (final session in sessions) session.key: session,
    };
    final sessionsWithPendingSets = <WorkoutDaySession>[
      for (final session in sessions)
        if (session.provider.getSetCounts().filledNotDone > 0) session,
    ];

    if (sessionsWithPendingSets.isNotEmpty) {
      final confirmCompleteAll = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(loc.notAllSetsConfirmed),
          content: const Text(
            'Es wurden noch nicht alle Sätze abgehakt. Möchtest du alle offenen Sätze abhaken und fortfahren?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(loc.cancelButton),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(loc.confirmAllSets),
            ),
          ],
        ),
      );

      if (!context.mounted || confirmCompleteAll != true) {
        return const WorkoutFinishResult(status: WorkoutFinishStatus.cancelled);
      }

      for (final session in sessionsWithPendingSets) {
        session.provider.completeAllFilledNotDone();
      }
    }

    final sessionGymId = sessions.isNotEmpty ? sessions.first.gymId : null;
    final activeGymId = sessionGymId ?? auth.gymCode ?? fallbackGymId;

    TrainingDoneOverlay.show(navigatorKey);

    SaveAllSessionsResult result;
    try {
      await settings.load(userId);
      result = await controller.saveAllSessions(
        userId: userId,
        gymId: activeGymId,
        showInLeaderboard: auth.showInLeaderboard ?? true,
        userName: auth.userName,
        gender: settings.gender,
        bodyWeightKg: settings.bodyWeightKg,
      );
    } catch (error, stackTrace) {
      await TrainingDoneOverlay.hide();
      debugPrint('❌ saveAllSessions failed unexpectedly: $error');
      debugPrint('$stackTrace');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${loc.errorPrefix}: $error')));
      }
      return const WorkoutFinishResult(status: WorkoutFinishStatus.failed);
    }

    if (result.saved > 0) {
      final resolvedPlanId = (planId != null && planId.isNotEmpty)
          ? planId
          : null;
      if (resolvedPlanId != null) {
        try {
          await FirestoreTrainingPlanSource().incrementCompletion(
            userId: userId,
            planId: resolvedPlanId,
          );
          if (container != null) {
            container.refresh(trainingPlanStatsProvider(resolvedPlanId));
          }
          final dayKey = logicDayKey(DateTime.now());
          await SessionMetaSource().upsertMeta(
            gymId: activeGymId,
            uid: userId,
            sessionId: dayKey,
            meta: {
              'dayKey': dayKey,
              'planId': resolvedPlanId,
              if (planName != null && planName.isNotEmpty) 'planName': planName,
            },
          );
        } catch (error, stackTrace) {
          debugPrint(
            '❌ Failed to update training plan meta for planId=$resolvedPlanId gym=$activeGymId: $error',
          );
          debugPrint('$stackTrace');
        }
      }

      for (final key in result.savedSessionKeys) {
        final session = sessionsByKey[key];
        if (session == null) continue;
        controller.closeSession(key);
      }

      if (resolvedPlanId != null) {
        controller.clearPlanContextForDay(gymId: activeGymId);
      }

      if (navigateToHomeProfileOnSuccess) {
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          AppRouter.home,
          (route) => false,
          arguments: 1,
        );
      }
    } else {
      await TrainingDoneOverlay.hide();
    }

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_buildResultMessage(loc, result))));
    }

    return WorkoutFinishResult(
      status: WorkoutFinishStatus.completed,
      saveResult: result,
      activeGymId: activeGymId,
    );
  }

  static String _buildResultMessage(
    AppLocalizations loc,
    SaveAllSessionsResult result,
  ) {
    if (result.attempted == 0) {
      return loc.noCompletedSets;
    }
    if (result.saved == 0) {
      final firstError = result.failedSessions.values.firstWhere(
        (error) => error != null && error.isNotEmpty,
        orElse: () => null,
      );
      return firstError ??
          '${loc.errorPrefix}: ${result.failedSessions.length}';
    }
    final savedText = result.saved == result.attempted
        ? loc.sessionSaved
        : '${loc.sessionSaved} (${result.saved}/${result.attempted})';
    if (!result.hasFailures) {
      return savedText;
    }
    final firstError = result.failedSessions.values.firstWhere(
      (error) => error != null && error.isNotEmpty,
      orElse: () => null,
    );
    final failureText =
        firstError ?? '${loc.errorPrefix}: ${result.failedSessions.length}';
    return '$savedText\n$failureText';
  }
}
