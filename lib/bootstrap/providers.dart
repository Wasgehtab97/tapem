// lib/bootstrap/providers.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/report/domain/usecases/get_all_log_timestamps.dart';
import '../features/report/domain/usecases/get_device_usage_stats.dart';
import '../services/membership_service.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/branding_provider.dart';
import '../core/providers/gym_provider.dart';

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

final authControllerProvider = ChangeNotifierProvider<AuthProvider>((ref) {
  throw UnimplementedError('AuthProvider not initialized');
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
  throw UnimplementedError('BrandingProvider not initialized');
});

final gymProvider = ChangeNotifierProvider<GymProvider>((ref) {
  throw UnimplementedError('GymProvider not initialized');
});

