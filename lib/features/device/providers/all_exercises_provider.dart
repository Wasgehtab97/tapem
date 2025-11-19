import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/providers/gym_scoped_resettable.dart';
import 'package:tapem/features/device/domain/models/exercise.dart';
import 'package:tapem/features/device/domain/usecases/get_exercises_for_device.dart';
import 'package:tapem/features/device/providers/device_riverpod.dart';

class AllExercisesProvider extends ChangeNotifier
    with GymScopedResettableChangeNotifier {
  final GetExercisesForDevice _getEx;
  AllExercisesProvider({required GetExercisesForDevice getEx}) : _getEx = getEx;

  final Map<String, List<Exercise>> _byDevice = {};
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, List<Exercise>> get byDevice => Map.unmodifiable(_byDevice);

  List<MapEntry<String, Exercise>> get allExercises => [
    for (final entry in _byDevice.entries)
      for (final ex in entry.value) MapEntry(entry.key, ex),
  ];

  Future<void> loadAll(
    String gymId,
    List<String> deviceIds,
    String userId,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final tmp = <String, List<Exercise>>{};
    try {
      for (final dId in deviceIds) {
        final ex = await _getEx.execute(gymId, dId, userId);
        tmp[dId] = ex;
      }
      _byDevice
        ..clear()
        ..addAll(tmp);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void resetGymScopedState() {
    _byDevice.clear();
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    disposeGymScopedRegistration();
    super.dispose();
  }
}

final allExercisesProvider = ChangeNotifierProvider<AllExercisesProvider>((ref) {
  final provider = AllExercisesProvider(
    getEx: ref.watch(getExercisesForDeviceProvider),
  );
  final gymScopedController = ref.watch(gymScopedStateControllerProvider);
  provider.registerGymScopedResettable(gymScopedController);

  ref.listen<AuthViewState>(
    authViewStateProvider,
    (previous, next) {
      final gymChanged = previous?.gymCode != next.gymCode;
      final userChanged = previous?.userId != next.userId;
      if (!next.isLoggedIn || next.gymCode == null || next.userId == null) {
        provider.resetGymScopedState();
        return;
      }
      if (gymChanged || userChanged) {
        provider.resetGymScopedState();
      }
    },
    fireImmediately: true,
  );

  ref.onDispose(provider.dispose);
  return provider;
});
