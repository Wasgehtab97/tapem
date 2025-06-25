import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:tapem/features/rank/domain/rank_repository.dart';
import 'package:tapem/features/rank/data/sources/firestore_rank_source.dart';
import 'package:tapem/features/rank/data/repositories/rank_repository_impl.dart';

class RankProvider extends ChangeNotifier {
  final RankRepository _repository;
  List<Map<String, dynamic>> _entries = [];
  StreamSubscription? _sub;

  RankProvider({RankRepository? repository})
      : _repository = repository ??
            RankRepositoryImpl(FirestoreRankSource());

  List<Map<String, dynamic>> get entries => _entries;

  void watch(String gymId) {
    _sub?.cancel();
    _sub = _repository.watchLeaderboard(gymId).listen((list) {
      _entries = list;
      notifyListeners();
    });
  }

  Future<void> addXp(
    String gymId,
    String userId,
    String deviceId,
    bool showInLeaderboard,
  ) {
    return _repository.addXp(gymId, userId, deviceId, showInLeaderboard);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
