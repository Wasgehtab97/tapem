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
  Map<String, int> _progressByChallengeId = const {};
  String? _activeUserId;
  int _progressToken = 0;
  StreamSubscription? _chSub;
  StreamSubscription? _badgeSub;
  StreamSubscription? _completedSub;

  ChallengeProvider({ChallengeRepository? repo})
    : _repo = repo ?? ChallengeRepositoryImpl(FirestoreChallengeSource());

  List<Challenge> get challenges => _challenges;
  List<CompletedChallenge> get completed => _completed;
  List<Badge> get badges => _badges;
  int progressFor(String challengeId) =>
      _progressByChallengeId[challengeId] ?? 0;

  void watchChallenges(String gymId, String userId) {
    debugPrint('👀 watchChallenges gymId=$gymId userId=$userId');
    _activeUserId = userId;
    _chSub?.cancel();
    _chSub = _repo.watchActiveChallenges(gymId).listen((list) {
      final completedIds = _completed.map((c) => c.id).toSet();
      _challenges = list.where((c) => !completedIds.contains(c.id)).toList();
      debugPrint('🔄 activeChallenges=${_challenges.length}');
      notifyListeners();
      unawaited(_refreshProgress());
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
      _challenges = _challenges
          .where((c) => !completedIds.contains(c.id))
          .toList();
      notifyListeners();
      unawaited(_refreshProgress());
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

  Future<void> checkChallenges(
    String gymId,
    String userId,
    String deviceId,
  ) async {
    await _repo.checkChallenges(gymId, userId, deviceId);
    await _refreshProgress();
  }

  Future<void> _refreshProgress() async {
    final userId = _activeUserId;
    if (userId == null || _challenges.isEmpty) {
      if (_progressByChallengeId.isNotEmpty) {
        _progressByChallengeId = const {};
        notifyListeners();
      }
      return;
    }

    final token = ++_progressToken;
    final challenges = List<Challenge>.from(_challenges);
    final entries = await Future.wait(
      challenges.map((challenge) async {
        try {
          final value = await _repo.getChallengeProgress(
            challenge: challenge,
            userId: userId,
          );
          return MapEntry(challenge.id, value);
        } catch (error) {
          debugPrint('⚠️ challenge progress error for ${challenge.id}: $error');
          return MapEntry(challenge.id, 0);
        }
      }),
    );

    if (token != _progressToken) {
      return;
    }

    _progressByChallengeId = <String, int>{
      for (final entry in entries) entry.key: entry.value,
    };
    notifyListeners();
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
