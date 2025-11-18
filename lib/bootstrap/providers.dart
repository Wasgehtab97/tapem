// lib/bootstrap/providers.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapem/core/providers/auth_provider.dart';

import '../core/providers/branding_provider.dart';
import '../core/providers/gym_provider.dart';
import '../core/providers/gym_scoped_resettable.dart';
import '../features/gym/data/sources/firestore_gym_source.dart';
import '../features/report/domain/usecases/get_all_log_timestamps.dart';
import '../features/report/domain/usecases/get_device_usage_stats.dart';
import '../services/membership_service.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences not initialized');
});

final getDeviceUsageStatsProvider = Provider<GetDeviceUsageStats>((ref) {
  throw UnimplementedError('GetDeviceUsageStats not initialized');
});

final getAllLogTimestampsProvider = Provider<GetAllLogTimestamps>((ref) {
  throw UnimplementedError('GetAllLogTimestamps not initialized');
});

final membershipServiceProvider = Provider<MembershipService>((ref) {
  return FirestoreMembershipService(firestore: FirebaseFirestore.instance);
});

final gymScopedStateControllerProvider = Provider<GymScopedStateController>((ref) {
  final controller = GymScopedStateController();
  ref.onDispose(controller.dispose);
  return controller;
});

final authControllerProvider =
    ChangeNotifierProvider<AuthProvider>((ref) {
  final membership = ref.watch(membershipServiceProvider);
  final controller = ref.watch(gymScopedStateControllerProvider);
  final provider = AuthProvider(
    membershipService: membership,
    gymScopedStateController: controller,
  );
  ref.onDispose(provider.dispose);
  return provider;
});

class AuthViewState {
  const AuthViewState({
    required this.isLoading,
    required this.isLoggedIn,
    required this.isAdmin,
    required this.gymContextStatus,
    required this.gymCode,
    required this.userId,
    required this.error,
  });

  final bool isLoading;
  final bool isLoggedIn;
  final bool isAdmin;
  final GymContextStatus gymContextStatus;
  final String? gymCode;
  final String? userId;
  final String? error;

  bool get hasError => error != null && error!.isNotEmpty;

  factory AuthViewState.fromAuth(AuthProvider auth) {
    return AuthViewState(
      isLoading: auth.isLoading,
      isLoggedIn: auth.isLoggedIn,
      isAdmin: auth.isAdmin,
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
  final controller = ref.watch(gymScopedStateControllerProvider);
  final provider = BrandingProvider(
    source: FirestoreGymSource(firestore: FirebaseFirestore.instance),
    membership: membership,
  );
  provider.registerGymScopedResettable(controller);

  void sync(AuthProvider auth) {
    provider.loadBrandingWithGym(auth.gymCode, auth.userId);
  }

  final auth = ref.watch(authControllerProvider);
  sync(auth);
  ref.listen<AuthProvider>(authControllerProvider, (previous, next) {
    if (previous?.gymCode != next.gymCode || previous?.userId != next.userId) {
      sync(next);
    }
  });

  ref.onDispose(provider.dispose);
  return provider;
});

final gymProvider = ChangeNotifierProvider<GymProvider>((ref) {
  final controller = GymProvider();
  final gymScoped = ref.watch(gymScopedStateControllerProvider);
  controller.registerGymScopedResettable(gymScoped);

  void sync(AuthProvider auth) {
    final gymId = auth.gymCode;
    if (gymId == null || gymId.isEmpty) {
      controller.resetGymScopedState();
    } else if (controller.lastRequestedGymId != gymId) {
      unawaited(controller.loadGymData(gymId));
    }
  }

  final auth = ref.watch(authControllerProvider);
  sync(auth);
  ref.listen<AuthProvider>(authControllerProvider, (previous, next) {
    if (previous?.gymCode != next.gymCode) {
      sync(next);
    }
  });

  ref.onDispose(controller.dispose);
  return controller;
});

