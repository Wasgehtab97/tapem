import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/features/gym/domain/models/gym_config.dart';

import 'auth_providers.dart' as auth;

class GymContextView {
  final String? gymId;
  final String? gymName;
  final GymConfig? gym;
  final bool isReady;
  final String? error;

  const GymContextView({
    required this.gymId,
    required this.gymName,
    required this.gym,
    required this.isReady,
    required this.error,
  });
}

final gymContextProvider = Provider<GymContextView>((ref) {
  final authState = ref.watch(auth.authViewStateProvider);
  final gymState = ref.watch(auth.gymProvider);
  final gymId = authState.gymCode;
  final gym = gymState.gym;
  final isReady = gymId != null && gymId.isNotEmpty && gym != null;
  return GymContextView(
    gymId: gymId,
    gymName: gym?.name,
    gym: gym,
    isReady: isReady,
    error: gymState.error,
  );
});
