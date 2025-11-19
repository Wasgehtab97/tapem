import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/auth_providers.dart';
import '../../../core/providers/firebase_provider.dart';
import 'friends_provider.dart';

enum PresenceState { workedOutToday, notWorkedOutToday, unknown }

class FriendPresenceState {
  const FriendPresenceState({
    this.states = const <String, PresenceState>{},
  });

  final Map<String, PresenceState> states;

  PresenceState stateFor(String uid) {
    return states[uid] ?? PresenceState.unknown;
  }

  FriendPresenceState copyWith({Map<String, PresenceState>? states}) {
    return FriendPresenceState(states: states ?? this.states);
  }
}

abstract class FriendPresenceStreamFactory {
  Stream<bool?> watchStats({required String uid, required String dayKey});
  Stream<bool> watchLogs({
    required String uid,
    required DateTime start,
    required DateTime end,
  });
}

class FirestoreFriendPresenceStreamFactory implements FriendPresenceStreamFactory {
  FirestoreFriendPresenceStreamFactory({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  @override
  Stream<bool?> watchStats({required String uid, required String dayKey}) {
    return _firestore
        .collection('stats')
        .doc(dayKey)
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snap) {
      if (!snap.exists) {
        return null;
      }
      return snap.data()?['hasWorkout'] == true;
    });
  }

  @override
  Stream<bool> watchLogs({
    required String uid,
    required DateTime start,
    required DateTime end,
  }) {
    return _firestore
        .collectionGroup('logs')
        .where('userId', isEqualTo: uid)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThan: Timestamp.fromDate(end))
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs.isNotEmpty);
  }
}

class FriendPresenceNotifier extends Notifier<FriendPresenceState> {
  final Map<String, StreamSubscription<bool?>> _statsSubs = {};
  final Map<String, StreamSubscription<bool>> _logSubs = {};
  Timer? _midnightTimer;
  late FriendPresenceStreamFactory _streamFactory;

  @override
  FriendPresenceState build() {
    _streamFactory = ref.watch(friendPresenceStreamFactoryProvider);
    _scheduleMidnightReset();

    ref.onDispose(() {
      for (final sub in _statsSubs.values) {
        sub.cancel();
      }
      for (final sub in _logSubs.values) {
        sub.cancel();
      }
      _midnightTimer?.cancel();
    });

    ref.listen<AuthViewState>(
      authViewStateProvider,
      (previous, next) {
        final userChanged = previous?.userId != next.userId;
        final gymChanged = previous?.gymCode != next.gymCode;
        if (!next.isLoggedIn || next.userId == null || next.userId!.isEmpty) {
          _reset();
          return;
        }
        if (userChanged || gymChanged) {
          _reset();
        }
      },
      fireImmediately: true,
    );

    ref.listen<List<String>>(
      friendIdsProvider,
      (previous, next) {
        _updateUids(next);
      },
      fireImmediately: true,
    );

    return const FriendPresenceState();
  }

  void _updateUids(List<String> uids) {
    final uniqueUids = uids.toSet().toList();
    for (final uid in uniqueUids) {
      if (!_statsSubs.containsKey(uid)) {
        _listenStats(uid);
      }
    }
    final remove = _statsSubs.keys.where((uid) => !uniqueUids.contains(uid)).toList();
    for (final uid in remove) {
      _statsSubs.remove(uid)?.cancel();
      _logSubs.remove(uid)?.cancel();
      _assign(uid, PresenceState.unknown);
    }
  }

  void _listenStats(String uid) {
    final dayKey = _todayKey();
    _statsSubs[uid]?.cancel();
    _statsSubs[uid] = _streamFactory
        .watchStats(uid: uid, dayKey: dayKey)
        .listen((hasWorkout) {
      if (hasWorkout == null) {
        _listenLogs(uid);
      } else {
        _logSubs.remove(uid)?.cancel();
        _assign(
          uid,
          hasWorkout
              ? PresenceState.workedOutToday
              : PresenceState.notWorkedOutToday,
        );
      }
    }, onError: (_) {
      _listenLogs(uid);
    });
  }

  void _listenLogs(String uid) {
    if (_logSubs.containsKey(uid)) {
      return;
    }
    final start = _todayStart();
    final end = start.add(const Duration(days: 1));
    _logSubs[uid] = _streamFactory
        .watchLogs(uid: uid, start: start, end: end)
        .listen((hasLogs) {
      _assign(
        uid,
        hasLogs
            ? PresenceState.workedOutToday
            : PresenceState.notWorkedOutToday,
      );
    }, onError: (_) {
      _assign(uid, PresenceState.unknown);
    });
  }

  void _assign(String uid, PresenceState presence) {
    final next = Map<String, PresenceState>.from(state.states);
    next[uid] = presence;
    state = state.copyWith(states: next);
  }

  DateTime _todayStart() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  String _todayKey() {
    final d = _todayStart();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  void _scheduleMidnightReset() {
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day + 1);
    final dur = next.difference(now);
    _midnightTimer = Timer(dur, _resetAndReschedule);
  }

  void _resetAndReschedule() {
    _reset();
    _scheduleMidnightReset();
  }

  void _reset() {
    for (final s in _statsSubs.values) {
      s.cancel();
    }
    for (final s in _logSubs.values) {
      s.cancel();
    }
    _statsSubs.clear();
    _logSubs.clear();
    state = const FriendPresenceState();
  }
}

final friendPresenceStreamFactoryProvider =
    Provider<FriendPresenceStreamFactory>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return FirestoreFriendPresenceStreamFactory(firestore: firestore);
});

final friendPresenceProvider =
    NotifierProvider<FriendPresenceNotifier, FriendPresenceState>(
  FriendPresenceNotifier.new,
);
