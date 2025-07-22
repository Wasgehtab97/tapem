import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:tapem/features/rank/domain/rank_repository.dart';
import 'package:tapem/features/rank/data/sources/firestore_rank_source.dart';
import 'package:tapem/features/rank/data/repositories/rank_repository_impl.dart';

class RankProvider extends ChangeNotifier {
  final RankRepository _repository;
  List<Map<String, dynamic>> _deviceEntries = [];
  StreamSubscription? _deviceSub;

  RankProvider({RankRepository? repository})
    : _repository = repository ?? RankRepositoryImpl(FirestoreRankSource());

  List<Map<String, dynamic>> get deviceEntries => _deviceEntries;

  void watchDevice(String gymId, String deviceId) {
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
    super.dispose();
  }
}
