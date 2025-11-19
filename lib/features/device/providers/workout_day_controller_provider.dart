// lib/features/device/providers/workout_day_controller_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/drafts/session_draft_repository_impl.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/providers/challenge_provider.dart';
import '../../../core/providers/gym_scoped_resettable.dart';
import '../../../core/providers/xp_provider.dart';
import '../../../core/services/workout_session_duration_service.dart';
import '../../../features/community/data/community_stats_writer.dart';
import '../../../services/membership_service.dart';
import '../presentation/controllers/workout_day_controller.dart';
import 'device_riverpod.dart';

final workoutDayControllerProvider =
    ChangeNotifierProvider<WorkoutDayController>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final membership = ref.watch(membershipServiceProvider);
  final controller = WorkoutDayController(
    firestore: firestore,
    membership: membership,
    deviceRepository: ref.watch(deviceRepositoryProvider),
    getDevicesForGym: ref.watch(getDevicesForGymProvider),
    communityStatsWriter: CommunityStatsWriter(
      firestore: firestore,
    ),
    createDraftRepository: () => SessionDraftRepositoryImpl(),
  );

  controller.registerGymScopedResettable(
    ref.watch(gymScopedStateControllerProvider),
  );
  controller.attachExternalServices(
    xpProvider: ref.read(xpProvider),
    challengeProvider: ref.read(challengeProvider),
    sessionDurationService: ref.read(workoutSessionDurationServiceProvider),
  );

  void handleAuth(AuthViewState state) {
    controller.setActiveUser(state.userId);
  }

  controller.updateMembership(membership);
  handleAuth(ref.read(authViewStateProvider));

  ref.listen<MembershipService>(
    membershipServiceProvider,
    (_, next) => controller.updateMembership(next),
  );
  ref.listen<AuthViewState>(
    authViewStateProvider,
    (_, next) => handleAuth(next),
    fireImmediately: false,
  );

  ref.onDispose(controller.dispose);
  return controller;
});
