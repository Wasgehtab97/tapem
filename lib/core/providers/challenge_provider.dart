import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/features/challenges/domain/models/challenge.dart';
import 'package:tapem/features/challenges/domain/models/badge.dart';
import 'package:tapem/features/challenges/domain/models/completed_challenge.dart';
import 'package:tapem/features/challenges/data/repositories/challenge_repository_impl.dart';
import 'package:tapem/features/challenges/data/sources/firestore_challenge_source.dart';
import 'package:tapem/features/challenges/domain/repositories/challenge_repository.dart';

class ChallengeProvider extends ChangeNotifier {
  final ChallengeRepository _repo;
  List<Challenge> _challenges = [];
  List<CompletedChallenge> _completed = [];
  List<Badge> _badges = [];
  StreamSubscription? _chSub;
  StreamSubscription? _badgeSub;
  StreamSubscription? _completedSub;

  ChallengeProvider({ChallengeRepository? repo})
    : _repo = repo ?? ChallengeRepositoryImpl(FirestoreChallengeSource());

  List<Challenge> get challenges => _challenges;
  List<CompletedChallenge> get completed => _completed;
  List<Badge> get badges => _badges;

  void watchChallenges(String gymId, String userId) {
    debugPrint('👀 watchChallenges gymId=$gymId userId=$userId');
    _chSub?.cancel();
    _chSub = _repo.watchActiveChallenges(gymId).listen((list) {
      final completedIds = _completed.map((c) => c.id).toSet();
      _challenges = list.where((c) => !completedIds.contains(c.id)).toList();
      debugPrint('🔄 activeChallenges=${_challenges.length}');
      notifyListeners();
    });
    watchCompletedChallenges(gymId, userId);
  }

  void watchCompletedChallenges(String gymId, String userId) {
    debugPrint('👀 watchCompletedChallenges gymId=$gymId userId=$userId');
    _completedSub?.cancel();
    _completedSub = _repo.watchCompletedChallenges(gymId, userId).listen((
      list,
    ) {
      _completed = list;
      debugPrint('🔄 completedChallenges=${list.length}');
      // Remove completed from active list
      final completedIds = _completed.map((c) => c.id).toSet();
      _challenges =
          _challenges.where((c) => !completedIds.contains(c.id)).toList();
      notifyListeners();
    });
  }

  void watchBadges(String userId) {
    debugPrint('👀 watchBadges userId=$userId');
    _badgeSub?.cancel();
    _badgeSub = _repo.watchBadges(userId).listen((list) {
      _badges = list;
      debugPrint('🔄 badges=${list.length}');
      notifyListeners();
    });
  }

  Future<void> checkChallenges(String gymId, String userId, String deviceId) {
    return _repo.checkChallenges(gymId, userId, deviceId);
  }

  @override
  void dispose() {
    _chSub?.cancel();
    _badgeSub?.cancel();
    _completedSub?.cancel();
    super.dispose();
  }
}

final challengeProvider = ChangeNotifierProvider<ChallengeProvider>((ref) {
  final provider = ChallengeProvider();
  ref.onDispose(provider.dispose);
  return provider;
});
