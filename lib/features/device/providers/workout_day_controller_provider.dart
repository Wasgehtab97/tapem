// lib/features/device/providers/workout_day_controller_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
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
  final controller = WorkoutDayController(
    firestore: FirebaseFirestore.instance,
    membership: ref.read(membershipServiceProvider),
    deviceRepository: ref.read(deviceRepositoryProvider),
    getDevicesForGym: ref.read(getDevicesForGymProvider),
    communityStatsWriter: CommunityStatsWriter(
      firestore: FirebaseFirestore.instance,
    ),
    createDraftRepository: () => SessionDraftRepositoryImpl(),
  );

  controller.registerGymScopedResettable(
    ref.read(gymScopedStateControllerProvider),
  );
  controller.attachExternalServices(
    xpProvider: ref.read(xpProvider),
    challengeProvider: ref.read(challengeProvider),
    sessionDurationService: ref.read(workoutSessionDurationServiceProvider),
  );

  void updateMembership() {
    controller.updateMembership(ref.read(membershipServiceProvider));
  }

  void updateAuth() {
    controller.setActiveUser(ref.read(authControllerProvider).userId);
  }

  updateMembership();
  updateAuth();

  ref.listen<AuthProvider>(authControllerProvider, (_, __) => updateAuth());
  ref.onDispose(controller.dispose);
  return controller;
});
