import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tapem/core/auth/role_utils.dart';

class ExperienceRankSignal {
  const ExperienceRankSignal({
    required this.currentRank,
    required this.currentXp,
    required this.xpToNextRank,
    required this.participantCount,
  });

  const ExperienceRankSignal.empty()
    : currentRank = null,
      currentXp = 0,
      xpToNextRank = null,
      participantCount = 0;

  final int? currentRank;
  final int currentXp;
  final int? xpToNextRank;
  final int participantCount;

  bool get hasPlacement => currentRank != null;
}

class ExperienceRankSignalService {
  ExperienceRankSignalService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<ExperienceRankSignal> fetch({
    required String gymId,
    required String userId,
  }) async {
    if (gymId.isEmpty || userId.isEmpty) {
      return const ExperienceRankSignal.empty();
    }

    try {
      final gymUsers = await _firestore
          .collection('gyms')
          .doc(gymId)
          .collection('users')
          .get();
      if (gymUsers.docs.isEmpty) {
        return const ExperienceRankSignal.empty();
      }

      final rows = await Future.wait(
        gymUsers.docs.map((gymUserDoc) async {
          final uid = gymUserDoc.id;
          final userSnap = await _firestore.collection('users').doc(uid).get();
          final userData = userSnap.data();
          if (userData == null) return null;

          final showInLeaderboard =
              userData['showInLeaderboard'] as bool? ?? true;
          final role = userData['role'] as String?;
          if (!showInLeaderboard || isAdminLikeRole(role)) return null;

          final statsSnap = await _firestore
              .collection('gyms')
              .doc(gymId)
              .collection('users')
              .doc(uid)
              .collection('rank')
              .doc('stats')
              .get();
          final stats = statsSnap.data();
          final xp = (stats?['dailyXP'] as num?)?.toInt() ?? 0;
          final username = ((userData['username'] as String?) ?? uid)
              .trim()
              .toLowerCase();

          return _ExperienceRankRow(uid: uid, xp: xp, sortKey: username);
        }),
      );

      final rankedRows = rows.whereType<_ExperienceRankRow>().toList()
        ..sort((a, b) {
          final xpCompare = b.xp.compareTo(a.xp);
          if (xpCompare != 0) return xpCompare;
          return a.sortKey.compareTo(b.sortKey);
        });

      if (rankedRows.isEmpty) {
        return const ExperienceRankSignal.empty();
      }

      final selfIndex = rankedRows.indexWhere((row) => row.uid == userId);
      if (selfIndex < 0) {
        return ExperienceRankSignal(
          currentRank: null,
          currentXp: 0,
          xpToNextRank: null,
          participantCount: rankedRows.length,
        );
      }

      final currentXp = rankedRows[selfIndex].xp;
      final xpToNext = selfIndex > 0
          ? math.max(0, rankedRows[selfIndex - 1].xp - currentXp)
          : 0;
      return ExperienceRankSignal(
        currentRank: selfIndex + 1,
        currentXp: currentXp,
        xpToNextRank: xpToNext,
        participantCount: rankedRows.length,
      );
    } on FirebaseException {
      return const ExperienceRankSignal.empty();
    }
  }
}

class _ExperienceRankRow {
  const _ExperienceRankRow({
    required this.uid,
    required this.xp,
    required this.sortKey,
  });

  final String uid;
  final int xp;
  final String sortKey;
}
