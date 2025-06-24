import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:tapem/features/rank/domain/repositories/rank_repository.dart';

class RankProvider extends ChangeNotifier {
  final RankRepository _repository;
  List<Map<String, dynamic>> _entries = [];
  StreamSubscription? _sub;

  RankProvider(this._repository);

  List<Map<String, dynamic>> get entries => _entries;

  void watch(String gymId) {
    _sub?.cancel();
    _sub = _repository.watchLeaderboard(gymId).listen((list) {
      _entries = list;
      notifyListeners();
    });
  }

  Future<void> addXp(String gymId, String userId, String deviceId) {
    return _repository.addXp(gymId, userId, deviceId);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
