// lib/core/providers/rank_provider.dart

import 'package:flutter/foundation.dart';
import 'package:tapem/features/rank/data/repositories/rank_repository_impl.dart';
import 'package:tapem/features/rank/data/sources/firestore_rank_source.dart';
import 'package:tapem/features/rank/data/device_xp.dart';

class RankProvider extends ChangeNotifier {
  final RankRepositoryImpl _repo;

  RankProvider({RankRepositoryImpl? repo})
      : _repo = repo ?? RankRepositoryImpl(FirestoreRankSource());

  bool _isLoading = false;
  String? _error;
  DeviceXp? _userXp;
  List<MapEntry<String, DeviceXp>> _leaderboard = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  DeviceXp? get userXp => _userXp;
  List<MapEntry<String, DeviceXp>> get leaderboard => List.unmodifiable(_leaderboard);

  Future<void> loadUserXp({
    required String gymId,
    required String deviceId,
    required String userId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _userXp = await _repo.getUserXp(
        gymId: gymId,
        deviceId: deviceId,
        userId: userId,
      );
    } catch (e, st) {
      _error = e.toString();
      debugPrintStack(label: 'RankProvider.loadUserXp', stackTrace: st);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadLeaderboard({
    required String gymId,
    required String deviceId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _leaderboard = await _repo.getLeaderboard(
        gymId: gymId,
        deviceId: deviceId,
      );
    } catch (e, st) {
      _error = e.toString();
      debugPrintStack(label: 'RankProvider.loadLeaderboard', stackTrace: st);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
