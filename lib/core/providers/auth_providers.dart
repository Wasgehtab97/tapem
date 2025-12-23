// lib/core/providers/auth_providers.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/gym/data/sources/firestore_gym_source.dart';
import '../../services/membership_service.dart';
import 'auth_provider.dart';
import 'branding_provider.dart';
import 'gym_provider.dart';
import 'gym_scoped_resettable.dart';

final authControllerProvider = ChangeNotifierProvider<AuthProvider>((ref) {
  final membership = ref.watch(membershipServiceProvider);
  final gymScopedController = ref.read(gymScopedStateControllerProvider);
  final auth = AuthProvider(
    membershipService: membership,
    gymScopedStateController: gymScopedController,
  );
  ref.onDispose(auth.dispose);
  return auth;
});

class AuthViewState implements GymContextState {
  const AuthViewState({
    required this.isLoading,
    required this.isLoggedIn,
    required this.isGuest,
    required this.isAdmin,
    required this.isCoach,
    required this.gymContextStatus,
    required this.gymCode,
    required this.userId,
    required this.error,
  });

  final bool isLoading;
  final bool isLoggedIn;
  final bool isGuest;
  final bool isAdmin;
  final bool isCoach;
  @override
  final GymContextStatus gymContextStatus;
  @override
  final String? gymCode;
  final String? userId;
  final String? error;

  bool get hasError => error != null && error!.isNotEmpty;

  factory AuthViewState.fromAuth(AuthProvider auth) {
    return AuthViewState(
      isLoading: auth.isLoading,
      isLoggedIn: auth.isLoggedIn,
      isGuest: auth.isGuest,
      isAdmin: auth.isAdmin,
      isCoach: auth.isCoach,
      gymContextStatus: auth.gymContextStatus,
      gymCode: auth.gymCode,
      userId: auth.userId,
      error: auth.error,
    );
  }
}

final authViewStateProvider = Provider<AuthViewState>((ref) {
  final auth = ref.watch(authControllerProvider);
  return AuthViewState.fromAuth(auth);
});

final brandingProvider = ChangeNotifierProvider<BrandingProvider>((ref) {
  final membership = ref.watch(membershipServiceProvider);
  final gymScopedController = ref.read(gymScopedStateControllerProvider);
  final branding = BrandingProvider(
    source: FirestoreGymSource(firestore: FirebaseFirestore.instance),
    membership: membership,
  );
  branding.registerGymScopedResettable(gymScopedController);

  ref.listen<AuthViewState>(
    authViewStateProvider,
    (previous, next) {
      final gymChanged = previous?.gymCode != next.gymCode;
      final userChanged = previous?.userId != next.userId;
      if (!gymChanged && !userChanged) {
        return;
      }
      branding.loadBrandingWithGym(next.gymCode, next.userId);
    },
    fireImmediately: true,
  );

  ref.onDispose(branding.dispose);
  return branding;
});

final gymProvider = ChangeNotifierProvider<GymProvider>((ref) {
  final gymScopedController = ref.read(gymScopedStateControllerProvider);
  final gym = GymProvider();
  gym.registerGymScopedResettable(gymScopedController);

  ref.listen<AuthViewState>(
    authViewStateProvider,
    (previous, next) {
      if (previous?.gymCode == next.gymCode) {
        return;
      }
      final gymId = next.gymCode;
      if (gymId == null || gymId.isEmpty) {
        gym.resetGymScopedState();
        return;
      }
      if (gym.lastRequestedGymId == gymId) {
        return;
      }
      unawaited(gym.loadGymData(gymId));
    },
    fireImmediately: true,
  );

  ref.onDispose(gym.dispose);
  return gym;
});
