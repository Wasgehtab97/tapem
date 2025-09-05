import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum PresenceState { workedOutToday, notWorkedOutToday, unknown }

class FriendPresenceProvider extends ChangeNotifier {
  FriendPresenceProvider({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance {
    _scheduleMidnightReset();
  }

  final FirebaseFirestore _firestore;
  final Map<String, PresenceState> _states = {};
  final Map<String, StreamSubscription> _statsSubs = {};
  final Map<String, StreamSubscription> _logSubs = {};

  Map<String, PresenceState> get states => Map.unmodifiable(_states);

  void updateUids(List<String> uids) {
    for (final uid in uids) {
      if (!_statsSubs.containsKey(uid)) {
        _listen(uid);
      }
    }
    final remove = _statsSubs.keys.where((u) => !uids.contains(u)).toList();
    for (final uid in remove) {
      _statsSubs.remove(uid)?.cancel();
      _logSubs.remove(uid)?.cancel();
      _states.remove(uid);
    }
  }

  PresenceState stateFor(String uid) {
    return _states[uid] ?? PresenceState.unknown;
  }

  void _listen(String uid) {
    final statsRef = _firestore
        .collection('stats')
        .doc(_todayKey())
        .collection('users')
        .doc(uid);
    _statsSubs[uid] = statsRef.snapshots().listen((snap) {
      if (snap.exists) {
        final has = snap.data()?['hasWorkout'] == true;
        _states[uid] =
            has ? PresenceState.workedOutToday : PresenceState.notWorkedOutToday;
        notifyListeners();
      } else {
        _listenLogs(uid);
      }
    }, onError: (_) {
      _listenLogs(uid);
    });
  }

  void _listenLogs(String uid) {
    if (_logSubs.containsKey(uid)) return;
    final start = _todayStart();
    final end = start.add(const Duration(days: 1));
    final q = _firestore
        .collectionGroup('logs')
        .where('userId', isEqualTo: uid)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThan: Timestamp.fromDate(end))
        .limit(1);
    _logSubs[uid] = q.snapshots().listen((snap) {
      _states[uid] = snap.docs.isNotEmpty
          ? PresenceState.workedOutToday
          : PresenceState.notWorkedOutToday;
      notifyListeners();
    }, onError: (_) {
      _states[uid] = PresenceState.unknown;
      notifyListeners();
    });
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
    _midnightTimer = Timer(dur, _reset);
  }

  Timer? _midnightTimer;

  void _reset() {
    for (final s in _statsSubs.values) {
      s.cancel();
    }
    for (final s in _logSubs.values) {
      s.cancel();
    }
    _statsSubs.clear();
    _logSubs.clear();
    _states.clear();
    notifyListeners();
    _scheduleMidnightReset();
  }

  @override
  void dispose() {
    for (final s in _statsSubs.values) {
      s.cancel();
    }
    for (final s in _logSubs.values) {
      s.cancel();
    }
    _midnightTimer?.cancel();
    super.dispose();
  }
}
