// lib/features/device/providers/workout_day_controller_provider.dart
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../bootstrap/navigation.dart';
import '../../../core/navigation/workout_flow_navigation.dart';
import '../../../core/drafts/session_draft_repository_impl.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/challenge_provider.dart';
import '../../../core/providers/firebase_provider.dart';
import '../../../core/providers/gym_scoped_resettable.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/providers/xp_provider.dart';
import '../../../core/services/workout_session_coordinator.dart';
import '../../../core/services/workout_session_duration_service.dart';
import '../../../features/community/data/community_stats_writer.dart';
import '../../../services/membership_service.dart';
import '../../training_details/providers/session_repository_provider.dart';
import '../presentation/controllers/workout_day_controller.dart';
import 'device_riverpod.dart';
import 'workout_data_repository_provider.dart';

void _workoutFlowLog(String message) {
  debugPrint('🏁 [WorkoutFlow] $message');
}

final ChangeNotifierProvider<WorkoutDayController>
workoutDayControllerProvider = ChangeNotifierProvider<WorkoutDayController>((
  ref,
) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final membership = ref.watch(membershipServiceProvider);
  final controller = WorkoutDayController(
    firestore: firestore,
    membership: membership,
    sessionRepository: ref.watch(sessionRepositoryProvider),
    syncService: ref.watch(syncServiceProvider),
    deviceRepository: ref.watch(deviceRepositoryProvider),
    workoutDataRepository: ref.watch(workoutDataRepositoryProvider),
    getDevicesForGym: ref.watch(getDevicesForGymProvider),
    communityStatsWriter: CommunityStatsWriter(firestore: firestore),
    createDraftRepository: () => SessionDraftRepositoryImpl(),
  );

  controller.registerGymScopedResettable(
    ref.watch(gymScopedStateControllerProvider),
  );
  WorkoutSessionCoordinator? boundCoordinator;

  void attachServices({
    XpProvider? xp,
    ChallengeProvider? challenge,
    WorkoutSessionDurationService? duration,
    WorkoutSessionCoordinator? coordinator,
  }) {
    controller.attachExternalServices(
      xpProvider: xp ?? ref.read(xpProvider),
      challengeProvider: challenge ?? ref.read(challengeProvider),
      sessionDurationService:
          duration ?? ref.read(workoutSessionDurationServiceProvider),
      sessionCoordinator:
          coordinator ?? ref.read(workoutSessionCoordinatorProvider),
    );
  }

  void bindAutoFinalizeHandler(WorkoutSessionCoordinator coordinator) {
    if (!identical(boundCoordinator, coordinator)) {
      boundCoordinator?.setAutoFinalizeHandler(null);
      if (boundCoordinator != null) {
        _workoutFlowLog('auto_finalize_handler_unbound');
      }
      boundCoordinator = coordinator;
    }
    _workoutFlowLog('auto_finalize_handler_bound');
    coordinator.setAutoFinalizeHandler((lastSetCompletedAt) async {
      try {
        final auth = ref.read(authControllerProvider);
        final state = ref.read(authViewStateProvider);
        final userId = state.userId;
        final gymId = state.gymCode;
        if (userId == null ||
            userId.isEmpty ||
            gymId == null ||
            gymId.isEmpty) {
          _workoutFlowLog(
            'auto_finalize_handler_skipped reason=missing_auth_context',
          );
          return;
        }

        _workoutFlowLog(
          'auto_finalize_handler_begin uid=$userId gym=$gymId lastSet=${lastSetCompletedAt.toIso8601String()}',
        );
        final anchorStartAt = coordinator.anchorStartAt;
        final anchorDayKey = coordinator.anchorDayKey;
        await controller.restoreDraftSessions(userId: userId, gymId: gymId);
        final sessions = controller.sessionsFor(userId: userId, gymId: gymId);
        final hasSaveableSessions = sessions.any(
          (session) => session.canShowSaveAction,
        );
        _workoutFlowLog(
          'auto_finalize_handler_sessions total=${sessions.length} saveable=$hasSaveableSessions',
        );

        String? gender;
        double? bodyWeightKg;
        if (hasSaveableSessions) {
          final settings = ref.read(settingsProvider);
          await settings.load(userId);
          gender = settings.gender;
          bodyWeightKg = settings.bodyWeightKg;
        }

        final result = await controller.endDay(
          userId: userId,
          gymId: gymId,
          showInLeaderboard: auth.showInLeaderboard ?? true,
          userName: auth.userName,
          gender: gender,
          bodyWeightKg: bodyWeightKg,
          finalizeReason: WorkoutFinalizeReason.autoInactivity,
          finalizeEndTime: lastSetCompletedAt,
          sessionAnchorStartTime: anchorStartAt,
          sessionAnchorDayKey: anchorDayKey,
        );
        _workoutFlowLog(
          'auto_finalize_handler_saved attempted=${result.attempted} saved=${result.saved} failed=${result.failedSessions.length}',
        );
        if (result.saved > 0) {
          _workoutFlowLog(
            'auto_finalize_navigate_profile reason=saved_sessions',
          );
          await navigateToHomeProfile(
            navigatorKey: navigatorKey,
            source: 'auto_finalize_handler',
          );
        }
      } catch (error, stackTrace) {
        _workoutFlowLog('auto_finalize_handler_provider_error error=$error');
        debugPrintStack(label: 'workout_flow_error', stackTrace: stackTrace);
        rethrow;
      }
    });
  }

  attachServices();
  bindAutoFinalizeHandler(ref.read(workoutSessionCoordinatorProvider));

  void handleAuth(AuthViewState state) {
    controller.setActiveUser(state.userId);
    final userId = state.userId;
    final gymId = state.gymCode;
    if (userId == null || userId.isEmpty || gymId == null || gymId.isEmpty) {
      return;
    }
    unawaited(controller.restoreDraftSessions(userId: userId, gymId: gymId));
  }

  controller.updateMembership(membership);
  handleAuth(ref.read(authViewStateProvider));

  ref.listen<MembershipService>(
    membershipServiceProvider,
    (_, next) => controller.updateMembership(next),
  );
  ref.listen<XpProvider>(xpProvider, (_, next) => attachServices(xp: next));
  ref.listen<ChallengeProvider>(
    challengeProvider,
    (_, next) => attachServices(challenge: next),
  );
  ref.listen<WorkoutSessionDurationService>(
    workoutSessionDurationServiceProvider,
    (_, next) => attachServices(duration: next),
  );
  ref.listen<WorkoutSessionCoordinator>(workoutSessionCoordinatorProvider, (
    previous,
    next,
  ) {
    if (identical(previous, next)) {
      return;
    }
    attachServices(coordinator: next);
    bindAutoFinalizeHandler(next);
  });
  ref.listen<AuthViewState>(
    authViewStateProvider,
    (_, next) => handleAuth(next),
    fireImmediately: false,
  );

  ref.onDispose(() {
    boundCoordinator?.setAutoFinalizeHandler(null);
    _workoutFlowLog('auto_finalize_handler_unbound');
    controller.dispose();
  });
  return controller;
});
