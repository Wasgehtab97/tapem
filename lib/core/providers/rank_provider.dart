import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/core/providers/gym_scoped_resettable.dart';
import 'package:tapem/features/rank/domain/rank_repository.dart';
import 'package:tapem/features/rank/data/sources/firestore_rank_source.dart';
import 'package:tapem/features/rank/data/repositories/rank_repository_impl.dart';

class RankProvider extends ChangeNotifier with GymScopedResettableChangeNotifier {
  final RankRepository _repository;
  List<Map<String, dynamic>> _deviceEntries = [];
  StreamSubscription? _deviceSub;
  String? _activeGymId;
  String? _activeDeviceId;

  RankProvider({RankRepository? repository})
    : _repository = repository ?? RankRepositoryImpl(FirestoreRankSource());

  List<Map<String, dynamic>> get deviceEntries => _deviceEntries;

  void watchDevice(String gymId, String deviceId) {
    if (_activeGymId == gymId && _activeDeviceId == deviceId) {
      return;
    }
    _activeGymId = gymId;
    _activeDeviceId = deviceId;
    _deviceSub?.cancel();
    _deviceSub = _repository.watchLeaderboard(gymId, deviceId).listen((list) {
      _deviceEntries = list;
      notifyListeners();
    });
  }

  Future<void> addXp(
    String gymId,
    String userId,
    String deviceId,
    String sessionId,
    bool showInLeaderboard,
  ) {
    return _repository.addXp(
      gymId,
      userId,
      deviceId,
      sessionId,
      showInLeaderboard,
    );
  }

  @override
  void dispose() {
    _deviceSub?.cancel();
    disposeGymScopedRegistration();
    super.dispose();
  }

  @override
  void resetGymScopedState() {
    _deviceSub?.cancel();
    _deviceSub = null;
    _activeGymId = null;
    _activeDeviceId = null;
    _deviceEntries = [];
    notifyListeners();
  }
}

final rankProvider = ChangeNotifierProvider<RankProvider>((ref) {
  final provider = RankProvider();
  provider.registerGymScopedResettable(
    ref.read(gymScopedStateControllerProvider),
  );
  ref.onDispose(provider.dispose);
  return provider;
});
