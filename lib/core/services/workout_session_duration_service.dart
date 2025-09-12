import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../time/logic_day.dart';
import '../utils/duration_format.dart';
import 'workout_timer_telemetry.dart';

enum StopResult { save, discard, cancel }

class WorkoutSessionDurationService extends ChangeNotifier {
  static const _prefsKeyPrefix = 'workoutTimer:';
  static const _queueKey = 'workoutTimerQueue';

  final FirebaseFirestore _firestore;
  final Uuid _uuid = const Uuid();
  final WorkoutTimerTelemetry? _telemetry;
  SharedPreferences? _prefs;

  bool _isRunning = false;
  int? _startEpochMs;
  String? _uid;
  String? _gymId;
  Timer? _ticker;
  final StreamController<Duration> _tickCtrl = StreamController.broadcast();

  WorkoutSessionDurationService({FirebaseFirestore? firestore, WorkoutTimerTelemetry? telemetry})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _telemetry = telemetry {
    _init();
  }

  bool get isRunning => _isRunning;
  Stream<Duration> get tickStream => _tickCtrl.stream;
  Duration get elapsed =>
      _startEpochMs != null
          ? Duration(milliseconds:
              DateTime.now().millisecondsSinceEpoch - _startEpochMs!)
          : Duration.zero;

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    // find any running state for current user? We cannot know uid yet
    // but we can scan keys.
    final keys = _prefs!.getKeys().where((k) => k.startsWith(_prefsKeyPrefix));
    if (keys.isNotEmpty) {
      final data = jsonDecode(_prefs!.getString(keys.first)!);
      _startEpochMs = data['startEpochMs'] as int?;
      _uid = data['uid'] as String?;
      _gymId = data['gymId'] as String?;
      if (_startEpochMs != null) {
        _isRunning = true;
        _startTicker();
        notifyListeners();
      }
    }

    await _flushQueue();
  }

  Future<void> start({required String uid, required String gymId}) async {
    if (_isRunning) return;
    _uid = uid;
    _gymId = gymId;
    final now = DateTime.now().millisecondsSinceEpoch;
    _startEpochMs = now;
    final data = jsonEncode({
      'startEpochMs': now,
      'uid': uid,
      'gymId': gymId,
    });
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setString('$_prefsKeyPrefix$uid', data);
    _isRunning = true;
    _startTicker();
    notifyListeners();
    _telemetry?.timerStart();
  }

  /// Prompts the user whether to save or discard the current session.
  ///
  /// Returns [StopResult.save] if the user chooses to persist the duration,
  /// [StopResult.discard] if it should be thrown away, or [StopResult.cancel]
  /// if the dialog was dismissed.
  Future<StopResult> confirmStop(BuildContext context) async {
    if (!_isRunning) return StopResult.cancel;
    final elapsedDur = elapsed;
    final locale = Localizations.localeOf(context);
    final formatted = formatDuration(elapsedDur, locale: locale);
    final result = await showDialog<StopResult>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Training beenden?'),
        content: Text('Dauer: $formatted. Möchtest du die Zeit speichern oder verwerfen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(StopResult.cancel),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(StopResult.discard),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Verwerfen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(StopResult.save),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
    return result ?? StopResult.cancel;
  }

  Future<void> save() async {
    if (!_isRunning || _uid == null || _gymId == null || _startEpochMs == null) {
      return;
    }
    final uid = _uid!;
    final gymId = _gymId!;
    final start = DateTime.fromMillisecondsSinceEpoch(_startEpochMs!);
    final end = DateTime.now();
    final durationMs = end.millisecondsSinceEpoch - _startEpochMs!;
    final tz = await FlutterTimezone.getLocalTimezone();
    final dayKey = logicDayKey(start);

    // query logs for existing sessionId
    String? sessionId;
    var hasSets = false;
    try {
      final startDay = DateTime(start.year, start.month, start.day);
      final endDay = startDay.add(const Duration(days: 1));
      final snap = await _firestore
          .collectionGroup('logs')
          .where('userId', isEqualTo: uid)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDay))
          .where('timestamp', isLessThan: Timestamp.fromDate(endDay))
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        sessionId = snap.docs.first.data()['sessionId'] as String?;
        hasSets = true;
        final ref = snap.docs.first.reference.parent.parent; // device doc
        if (ref != null) {
          final gymDoc = ref.parent.parent;
          if (gymDoc != null) {
            // ensure gymId from logs matches stored gymId
            // not enforcing; just proceed
          }
        }
      }
    } catch (_) {
      // ignore
    }
    sessionId ??= _uuid.v4();

    final metaRef = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('users')
        .doc(uid)
        .collection('session_meta')
        .doc(sessionId);

    final payload = {
      'sessionId': sessionId,
      'uid': uid,
      'gymId': gymId,
      'startTime': Timestamp.fromDate(start),
      'endTime': Timestamp.fromDate(end),
      'durationMs': durationMs,
      'dayKey': dayKey,
      'tz': tz,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      await metaRef.set(payload, SetOptions(merge: true));
    } on FirebaseException {
      await _enqueuePersist(payload);
    }

    _telemetry?.timerStopSave(
        durationMs: durationMs, dayKey: dayKey, hasSets: hasSets);

    await _clearLocal();
  }

  Future<void> discard() async {
    if (!_isRunning || _startEpochMs == null) return;
    final start = DateTime.fromMillisecondsSinceEpoch(_startEpochMs!);
    final durationMs = DateTime.now().millisecondsSinceEpoch - _startEpochMs!;
    final dayKey = logicDayKey(start);
    _telemetry?.timerStopDiscard(
        durationMs: durationMs, dayKey: dayKey, hasSets: false);
    await _clearLocal();
  }

  Future<void> _clearLocal() async {
    final uid = _uid;
    _isRunning = false;
    _startEpochMs = null;
    _uid = null;
    _gymId = null;
    _ticker?.cancel();
    _tickCtrl.add(Duration.zero);
    notifyListeners();
    if (uid != null) {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.remove('$_prefsKeyPrefix$uid');
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isRunning && _startEpochMs != null) {
        _tickCtrl.add(elapsed);
      }
    });
  }

  Future<void> _enqueuePersist(Map<String, dynamic> payload) async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    final list = prefs.getStringList(_queueKey) ?? [];
    list.add(jsonEncode(payload));
    await prefs.setStringList(_queueKey, list);
  }

  Future<void> _flushQueue() async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    final list = prefs.getStringList(_queueKey) ?? [];
    if (list.isEmpty) return;

    final remaining = <String>[];
    for (final item in list) {
      try {
        final data = jsonDecode(item) as Map<String, dynamic>;
        final gymId = data['gymId'] as String;
        final uid = data['uid'] as String;
        final sessionId = data['sessionId'] as String;
        final ref = _firestore
            .collection('gyms')
            .doc(gymId)
            .collection('users')
            .doc(uid)
            .collection('session_meta')
            .doc(sessionId);
        await ref.set(data, SetOptions(merge: true));
      } catch (_) {
        remaining.add(item);
      }
    }
    await prefs.setStringList(_queueKey, remaining);
  }
}


