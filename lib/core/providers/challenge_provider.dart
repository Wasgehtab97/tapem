import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:tapem/features/challenges/domain/models/challenge.dart';
import 'package:tapem/features/challenges/domain/models/badge.dart';
import 'package:tapem/features/challenges/data/repositories/challenge_repository_impl.dart';
import 'package:tapem/features/challenges/data/sources/firestore_challenge_source.dart';
import 'package:tapem/features/challenges/domain/repositories/challenge_repository.dart';

class ChallengeProvider extends ChangeNotifier {
  final ChallengeRepository _repo;
  List<Challenge> _challenges = [];
  List<Badge> _badges = [];
  StreamSubscription? _chSub;
  StreamSubscription? _badgeSub;

  ChallengeProvider({ChallengeRepository? repo})
      : _repo = repo ??
            ChallengeRepositoryImpl(FirestoreChallengeSource());

  List<Challenge> get challenges => _challenges;
  List<Badge> get badges => _badges;

  void watchChallenges() {
    _chSub?.cancel();
    _chSub = _repo.watchActiveChallenges().listen((list) {
      _challenges = list;
      notifyListeners();
    });
  }

  void watchBadges(String userId) {
    _badgeSub?.cancel();
    _badgeSub = _repo.watchBadges(userId).listen((list) {
      _badges = list;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _chSub?.cancel();
    _badgeSub?.cancel();
    super.dispose();
  }
}
