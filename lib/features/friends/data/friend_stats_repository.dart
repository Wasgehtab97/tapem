import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:tapem/features/rank/domain/services/level_service.dart';

class FriendStatsRepository {
  FriendStatsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<FriendStats> fetchStats(String uid, String? primaryGymId) async {
    // If we have a primary gym, try that first.
    // If not, or if it fails/returns empty, we might return defaults.
    // For now, consistent with LeaderboardScreen, we look at the primary gym stats.
    
    if (primaryGymId == null || primaryGymId.isEmpty) {
      return FriendStats.zero();
    }

    try {
      final statsDoc = await _firestore
          .collection('gyms')
          .doc(primaryGymId)
          .collection('users')
          .doc(uid)
          .collection('rank')
          .doc('stats')
          .get();
      
      final data = statsDoc.data();
      final totalXp = (data?['dailyXP'] as num?)?.toInt() ?? 0;
      
      return _resolveStats(totalXp);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FriendStats] Failed to fetch stats for $uid: $e');
      }
      return FriendStats.zero();
    }
  }

  FriendStats _resolveStats(int totalXp) {
    // Logic from LeaderboardScreen / LevelService
    final xpPerLevel = LevelService.xpPerLevel;
    final maxLevel = LevelService.maxLevel;
    
    var level = (totalXp ~/ xpPerLevel) + 1;
    if (level > maxLevel) level = maxLevel;
    
    var xpInLevel = totalXp % xpPerLevel;
    if (level >= maxLevel) xpInLevel = 0;
    
    final progress = level >= maxLevel ? 1.0 : xpInLevel / xpPerLevel;

    return FriendStats(
      level: level,
      xpInLevel: xpInLevel,
      totalXp: totalXp,
      progress: progress,
    );
  }
}

class FriendStats {
  final int level;
  final int xpInLevel;
  final int totalXp;
  final double progress;

  const FriendStats({
    required this.level,
    required this.xpInLevel,
    required this.totalXp,
    required this.progress,
  });

  factory FriendStats.zero() {
    return const FriendStats(
      level: 1,
      xpInLevel: 0,
      totalXp: 0,
      progress: 0.0,
    );
  }
}
