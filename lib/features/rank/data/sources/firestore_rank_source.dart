import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

import 'package:tapem/core/logging/elog.dart';
import 'package:tapem/core/logging/firestore_read_logger.dart';
import 'package:tapem/core/logging/xp_trace.dart';
import 'package:tapem/core/time/logic_day.dart';
import 'package:tapem/features/xp/domain/device_xp_result.dart';

import '../../domain/models/level_info.dart';
import '../../domain/services/level_service.dart';

class FirestoreRankSource {
  final FirebaseFirestore _firestore;
  final Map<String, String?> _usernameCache = {};
  final Map<String, DateTime> _usernameExpiry = {};
  final Map<String, _LeaderboardCacheEntry> _leaderboardCache = {};
  final Duration _usernameTtl = const Duration(minutes: 30);
  final Duration _leaderboardTtl = const Duration(seconds: 30);

  FirestoreRankSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<DeviceXpResult> addXp({
    required String gymId,
    required String userId,
    required String deviceId,
    required String sessionId,
    required bool showInLeaderboard,
    required bool isMulti,
    String? exerciseId,
    required String traceId,
  }) async {
    assert(LevelService.xpPerSession == 50);
    assert(deviceId.isNotEmpty);
    final dayKey = logicDayKey(DateTime.now().toUtc());
    final lbUser = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('devices')
        .doc(deviceId)
        .collection('leaderboard')
        .doc(userId);
    final lbSess = lbUser.collection('sessions').doc(sessionId);
    final lbDay = lbUser.collection('days').doc(dayKey);
    try {
      final result = await _runTransactionWithRetry<DeviceXpResult>(
        (tx) async {
          XpTrace.log('TXN_READ', {
            'path': lbUser.path,
            'context': 'rank.addXp.user',
            'traceId': traceId,
          });
          FirestoreReadLogger.logStart(
            scope: 'rank.addXp',
            path: lbUser.path,
            operation: 'tx.get',
            traceId: traceId,
          );
          final userSnap = await tx.get(lbUser);
          FirestoreReadLogger.logResult(
            scope: 'rank.addXp',
            path: lbUser.path,
            exists: userSnap.exists,
            fromCache: userSnap.metadata.isFromCache,
            traceId: traceId,
          );
          XpTrace.log('TXN_READ_RESULT', {
            'path': lbUser.path,
            'exists': userSnap.exists,
            'traceId': traceId,
          });
          XpTrace.log('TXN_READ', {
            'path': lbSess.path,
            'context': 'rank.addXp.session',
            'traceId': traceId,
          });
          FirestoreReadLogger.logStart(
            scope: 'rank.addXp',
            path: lbSess.path,
            operation: 'tx.get',
            traceId: traceId,
          );
          final sessSnap = await tx.get(lbSess);
          FirestoreReadLogger.logResult(
            scope: 'rank.addXp',
            path: lbSess.path,
            exists: sessSnap.exists,
            fromCache: sessSnap.metadata.isFromCache,
            traceId: traceId,
          );
          XpTrace.log('TXN_READ', {
            'existsSessionDoc': sessSnap.exists,
            'xpCurrent': (userSnap.data()?['xp'] as int?) ?? 0,
            'levelCurrent': (userSnap.data()?['level'] as int?) ?? 1,
            'traceId': traceId,
          });

          if (sessSnap.exists) {
            XpTrace.log('TXN_DECISION', {
              'result': 'alreadySession',
              'showInLeaderboard': showInLeaderboard,
              'isMulti': isMulti,
              'exerciseId': exerciseId ?? '',
              'traceId': traceId,
            });
            return DeviceXpResult.idempotentHit;
          }

          const xpDelta = LevelService.xpPerSession;
          var info = LevelInfo.fromMap(userSnap.data());
          info = LevelService().addXp(info, xpDelta);
          final xpAfter = info.xp;

          if (!userSnap.exists) {
            tx.set(lbUser, {
              ...info.toMap(),
              'userId': userId,
              'showInLeaderboard': showInLeaderboard,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          } else {
            tx.update(lbUser, {
              'xp': info.xp,
              'level': info.level,
              'updatedAt': FieldValue.serverTimestamp(),
              if (!(userSnap.data()?.containsKey('userId') ?? false))
                'userId': userId,
              if (!(userSnap.data()?.containsKey('showInLeaderboard') ?? false))
                'showInLeaderboard': showInLeaderboard,
            });
          }

          tx.set(lbDay, {
            'creditedAt': FieldValue.serverTimestamp(),
            'sessionCount': FieldValue.increment(1),
          }, SetOptions(merge: true));
          tx.set(lbSess, {
            'sessionId': sessionId,
            'creditedAt': FieldValue.serverTimestamp(),
          });

          XpTrace.log('TXN_WRITE', {
            'deltaXp': xpDelta,
            'newXp': xpAfter,
            'newLevel': info.level,
            'wroteSessionMarker': true,
            'wroteDayMarker': true,
            'traceId': traceId,
          });

          return DeviceXpResult.okAdded;
        },
        traceId: traceId,
      );

      XpTrace.log('TXN_COMMIT', {
        'result': result.name,
        'traceId': traceId,
      });
      if (result == DeviceXpResult.okAdded ||
          result == DeviceXpResult.okAddedNoLeaderboard) {
        _leaderboardCache.remove('${gymId}_$deviceId');
      }
      return result;
    } on FirebaseException catch (e, st) {
      XpTrace.log('TXN_ERROR', {
        'code': e.code,
        'path': lbUser.path,
        'traceId': traceId,
      });
      if (e.code == 'permission-denied') {
        elogRank('SECURITY_DENIED', {
          'action': 'leaderboard write',
          'gymId': gymId,
          'deviceId': deviceId,
          'uid': userId,
          'reason': 'rules-path',
        });
        return DeviceXpResult.okAddedNoLeaderboard;
      }
      elogError('TXN_FIREBASE_ERROR', e, st, {
        'userPath': lbUser.path,
        'dayKey': dayKey,
      });
      return DeviceXpResult.error;
    }
  }

  Future<T> _runTransactionWithRetry<T>(
    Future<T> Function(Transaction tx) body, {
    required String traceId,
    int maxRetries = 3,
  }) async {
    var delayMs = 200;
    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        return await _firestore.runTransaction<T>(
          (tx) => body(tx),
          maxAttempts: 5,
        );
      } on FirebaseException catch (e) {
        if (e.code != 'resource-exhausted' || attempt == maxRetries) {
          rethrow;
        }
        XpTrace.log('TXN_RETRY', {
          'traceId': traceId,
          'attempt': attempt + 1,
          'code': e.code,
        });
        await Future<void>.delayed(Duration(milliseconds: delayMs));
        delayMs = delayMs >= 1600 ? 1600 : delayMs * 2;
      }
    }
    throw StateError('Retry loop exited unexpectedly for $traceId');
  }

  Future<List<Map<String, dynamic>>> fetchLeaderboard(
    String gymId,
    String deviceId,
  ) async {
    final cacheKey = '${gymId}_$deviceId';
    final cached = _leaderboardCache[cacheKey];
    if (cached != null && !cached.isExpired(_leaderboardTtl)) {
      FirestoreReadLogger.logCacheHit(
        scope: 'rank.leaderboard',
        path: 'gyms/$gymId/devices/$deviceId/leaderboard',
      );
      return cached.payload;
    }
    final query = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('devices')
        .doc(deviceId)
        .collection('leaderboard')
        .where('showInLeaderboard', isEqualTo: true)
        .orderBy('level', descending: true)
        .orderBy('xp', descending: true)
        .limit(50);
    FirestoreReadLogger.logStart(
      scope: 'rank.leaderboard',
      path: 'gyms/$gymId/devices/$deviceId/leaderboard',
      operation: 'get',
    );
    final snap = await query.get();
    FirestoreReadLogger.logResult(
      scope: 'rank.leaderboard',
      path: 'gyms/$gymId/devices/$deviceId/leaderboard',
      count: snap.size,
      fromCache: snap.metadata.isFromCache,
    );

    final missing = <String>[];
    for (final doc in snap.docs) {
      if (!_usernameCache.containsKey(doc.id)) {
        missing.add(doc.id);
      }
    }
    if (missing.isNotEmpty) {
      await _warmUsernames(missing);
    }

    final result = [
      for (final doc in snap.docs)
        {
          'userId': doc.id,
          'username': _usernameCache[doc.id],
          ...doc.data(),
        }
    ];
    _leaderboardCache[cacheKey] =
        _LeaderboardCacheEntry(DateTime.now(), result);
    return result;
  }

  Future<void> _warmUsernames(List<String> uids) async {
    const chunkSize = 10;
    final now = DateTime.now();
    final filtered = <String>[];
    for (final uid in uids) {
      final expiry = _usernameExpiry[uid];
      if (expiry != null && now.isBefore(expiry)) {
        continue;
      }
      filtered.add(uid);
    }
    for (var i = 0; i < filtered.length; i += chunkSize) {
      final chunk = filtered.sublist(
        i,
        i + chunkSize > filtered.length ? filtered.length : i + chunkSize,
      );
      try {
        FirestoreReadLogger.logStart(
          scope: 'rank.userWarm',
          path: 'users/${chunk.length}',
          operation: 'get',
          reason: 'leaderboardWarm',
        );
        final snap = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        FirestoreReadLogger.logResult(
          scope: 'rank.userWarm',
          path: 'users/${chunk.length}',
          count: snap.size,
          fromCache: snap.metadata.isFromCache,
        );
        for (final doc in snap.docs) {
          _usernameCache[doc.id] = doc.data()['username'] as String?;
          _usernameExpiry[doc.id] = now.add(_usernameTtl);
        }
        for (final uid in chunk) {
          _usernameCache.putIfAbsent(uid, () => null);
          _usernameExpiry[uid] = now.add(_usernameTtl);
        }
      } catch (_) {
        for (final uid in chunk) {
          _usernameCache[uid] ??= null;
          _usernameExpiry[uid] = now.add(_usernameTtl);
        }
      }
    }
  }

  // Removed weekly and monthly leaderboard watchers
}

class _LeaderboardCacheEntry {
  _LeaderboardCacheEntry(this.timestamp, this.payload);

  final DateTime timestamp;
  final List<Map<String, dynamic>> payload;

  bool isExpired(Duration ttl) => DateTime.now().difference(timestamp) > ttl;
}
