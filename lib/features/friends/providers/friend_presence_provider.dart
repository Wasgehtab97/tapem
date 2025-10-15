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
  final Set<String> _trackedUids = {};
  final Map<String, DateTime> _lastFetch = {};
  final Set<String> _loading = {};
  // Presence updates are informational only. Polling every ten minutes keeps
  // Firestore reads low even after hot restarts, while still giving users an
  // up-to-date view whenever they open the friends screen.
  final Duration _pollInterval = const Duration(minutes: 10);
  final Duration _cacheTtl = const Duration(minutes: 10);

  Timer? _midnightTimer;
  Timer? _pollTimer;

  Map<String, PresenceState> get states => Map.unmodifiable(_states);

  void updateUids(List<String> uids) {
    final incoming = uids.toSet();
    final newlyTracked = incoming.difference(_trackedUids);
    final removed = _trackedUids.difference(incoming).toList();

    var changed = false;

    for (final uid in newlyTracked) {
      _trackedUids.add(uid);
      _states.putIfAbsent(uid, () => PresenceState.unknown);
      unawaited(_loadPresence(uid, force: true));
      changed = true;
    }

    for (final uid in removed) {
      _trackedUids.remove(uid);
      _states.remove(uid);
      _lastFetch.remove(uid);
      changed = true;
    }

    if (changed) {
      notifyListeners();
    }

    _ensurePolling();
  }

  PresenceState stateFor(String uid) {
    return _states[uid] ?? PresenceState.unknown;
  }

  void _ensurePolling() {
    if (_trackedUids.isEmpty) {
      _pollTimer?.cancel();
      _pollTimer = null;
      return;
    }
    _pollTimer ??= Timer.periodic(_pollInterval, (_) {
      unawaited(_poll());
    });
  }

  Future<void> refresh() async {
    await _poll(force: true);
  }

  void overridePresence(String uid, PresenceState state) {
    final previous = _states[uid];
    if (previous == state) {
      final last = _lastFetch[uid];
      if (last != null && DateTime.now().difference(last) < _cacheTtl) {
        return;
      }
    }
    _states[uid] = state;
    _lastFetch[uid] = DateTime.now();
    notifyListeners();
  }

  Future<void> _poll({bool force = false}) async {
    for (final uid in _trackedUids) {
      await _loadPresence(uid, force: force);
    }
  }

  Future<void> _loadPresence(String uid, {bool force = false}) async {
    if (_loading.contains(uid)) {
      return;
    }
    final last = _lastFetch[uid];
    if (!force && last != null && DateTime.now().difference(last) < _cacheTtl) {
      return;
    }
    _loading.add(uid);
    try {
      final presenceRef = _firestore
          .collection('dailyPresence')
          .doc(_todayKey())
          .collection('users')
          .doc(uid);
      final snap = await presenceRef.get();
      PresenceState newState;
      if (snap.exists) {
        final workedOut = snap.data()?['workedOut'] == true;
        newState = workedOut
            ? PresenceState.workedOutToday
            : PresenceState.notWorkedOutToday;
      } else {
        newState = PresenceState.notWorkedOutToday;
      }

      _states[uid] = newState;
      _lastFetch[uid] = DateTime.now();
      notifyListeners();
    } catch (_) {
      _states[uid] = PresenceState.unknown;
      notifyListeners();
    } finally {
      _loading.remove(uid);
    }
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

  void _reset() {
    _states.clear();
    _lastFetch.clear();
    notifyListeners();
    for (final uid in _trackedUids) {
      unawaited(_loadPresence(uid, force: true));
    }
    _scheduleMidnightReset();
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    _pollTimer?.cancel();
    _loading.clear();
    super.dispose();
  }
}
