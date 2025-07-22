import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:tapem/features/rank/domain/rank_repository.dart';
import 'package:tapem/features/rank/data/sources/firestore_rank_source.dart';
import 'package:tapem/features/rank/data/repositories/rank_repository_impl.dart';

class RankProvider extends ChangeNotifier {
  final RankRepository _repository;
  List<Map<String, dynamic>> _deviceEntries = [];
  List<Map<String, dynamic>> _weeklyEntries = [];
  List<Map<String, dynamic>> _monthlyEntries = [];
  StreamSubscription? _deviceSub;
  StreamSubscription? _weeklySub;
  StreamSubscription? _monthlySub;

  RankProvider({RankRepository? repository})
    : _repository = repository ?? RankRepositoryImpl(FirestoreRankSource());

  List<Map<String, dynamic>> get deviceEntries => _deviceEntries;
  List<Map<String, dynamic>> get weeklyEntries => _weeklyEntries;
  List<Map<String, dynamic>> get monthlyEntries => _monthlyEntries;

  void watchDevice(String gymId, String deviceId) {
    _deviceSub?.cancel();
    _deviceSub = _repository.watchLeaderboard(gymId, deviceId).listen((list) {
      _deviceEntries = list;
      notifyListeners();
    });
  }

  void watchWeekly(String gymId, String weekId) {
    _weeklySub?.cancel();
    _weeklySub =
        _repository.watchWeeklyLeaderboard(gymId, weekId).listen((list) {
      _weeklyEntries = list;
      notifyListeners();
    });
  }

  void watchMonthly(String gymId, String monthId) {
    _monthlySub?.cancel();
    _monthlySub =
        _repository.watchMonthlyLeaderboard(gymId, monthId).listen((list) {
      _monthlyEntries = list;
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
    _weeklySub?.cancel();
    _monthlySub?.cancel();
    super.dispose();
  }
}
