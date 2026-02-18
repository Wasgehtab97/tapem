import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/core/navigation/workout_flow_navigation.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/settings_provider.dart';
import 'package:tapem/core/services/workout_session_coordinator.dart';
import 'package:tapem/core/time/logic_day.dart';
import 'package:tapem/features/device/presentation/controllers/workout_day_controller.dart';
import 'package:tapem/features/device/presentation/workout_flow_error.dart';
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
    this.errorCode,
  });

  final WorkoutFinishStatus status;
  final SaveAllSessionsResult? saveResult;
  final String? activeGymId;
  final WorkoutFlowErrorCode? errorCode;

  bool get savedAny => (saveResult?.saved ?? 0) > 0;
}

class WorkoutFinishFlow {
  const WorkoutFinishFlow._();
  static const Duration _endDayTimeout = Duration(seconds: 15);

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
    String? sessionAnchorDayKey,
    DateTime? sessionAnchorStartTime,
  }) async {
    final loc = AppLocalizations.of(context)!;
    final userId = auth.userId;
    if (userId == null || userId.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              workoutFlowErrorMessage(
                loc,
                WorkoutFlowErrorCode.missingUserContext,
              ),
            ),
          ),
        );
      }
      return const WorkoutFinishResult(
        status: WorkoutFinishStatus.failed,
        errorCode: WorkoutFlowErrorCode.missingUserContext,
      );
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
      try {
        await settings.load(userId).timeout(const Duration(seconds: 1));
      } catch (error, stackTrace) {
        debugPrint(
          '⚠️ [WorkoutFinishFlow] settings load skipped (offline/timeout): $error',
        );
        debugPrint('$stackTrace');
      }
      result = await controller
          .endDay(
            userId: userId,
            gymId: activeGymId,
            showInLeaderboard: auth.showInLeaderboard ?? true,
            userName: auth.userName,
            gender: settings.gender,
            bodyWeightKg: settings.bodyWeightKg,
            finalizeReason: WorkoutFinalizeReason.manualSave,
            sessionAnchorStartTime: sessionAnchorStartTime,
            sessionAnchorDayKey: sessionAnchorDayKey,
          )
          .timeout(_endDayTimeout);
    } catch (error, stackTrace) {
      await TrainingDoneOverlay.hide();
      debugPrint('❌ saveAllSessions failed unexpectedly: $error');
      debugPrint('$stackTrace');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              workoutFlowErrorMessage(loc, WorkoutFlowErrorCode.saveFailed),
            ),
          ),
        );
      }
      return const WorkoutFinishResult(
        status: WorkoutFinishStatus.failed,
        errorCode: WorkoutFlowErrorCode.saveFailed,
      );
    }

    if (result.saved > 0) {
      TrainingDoneOverlay.clear();
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
          final resolvedAnchorStart = sessionAnchorStartTime;
          final dayKey =
              (sessionAnchorDayKey != null &&
                  sessionAnchorDayKey.trim().isNotEmpty)
              ? sessionAnchorDayKey.trim()
              : (resolvedAnchorStart != null
                    ? logicDayKey(resolvedAnchorStart)
                    : null);
          if (dayKey != null) {
            await SessionMetaSource().upsertMeta(
              gymId: activeGymId,
              uid: userId,
              sessionId: dayKey,
              meta: {
                'dayKey': dayKey,
                'anchorDayKey': dayKey,
                if (resolvedAnchorStart != null)
                  'anchorStartTime': Timestamp.fromDate(resolvedAnchorStart),
                if (resolvedAnchorStart != null)
                  'anchorStartEpochMs':
                      resolvedAnchorStart.millisecondsSinceEpoch,
                'planId': resolvedPlanId,
                if (planName != null && planName.isNotEmpty)
                  'planName': planName,
              },
            );
          } else {
            debugPrint(
              '⚠️ Skipping training plan session_meta upsert because no session anchor day is available.',
            );
          }
        } catch (error, stackTrace) {
          debugPrint(
            '❌ Failed to update training plan meta for planId=$resolvedPlanId gym=$activeGymId: $error',
          );
          debugPrint('$stackTrace');
        }
      }

      if (navigateToHomeProfileOnSuccess) {
        await navigateToHomeProfile(
          navigatorKey: navigatorKey,
          source: 'manual_finish_flow',
        );
      }
    } else {
      await TrainingDoneOverlay.hide();
    }

    return WorkoutFinishResult(
      status: WorkoutFinishStatus.completed,
      saveResult: result,
      activeGymId: activeGymId,
    );
  }
}
