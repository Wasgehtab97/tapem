import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../time/logic_day.dart';
import '../utils/duration_format.dart';

enum StopResult { save, discard, cancel }

class WorkoutSessionDurationService extends ChangeNotifier {
  static const _prefsKeyPrefix = 'workoutTimer:';

  final FirebaseFirestore _firestore;
  final Uuid _uuid = const Uuid();
  SharedPreferences? _prefs;

  bool _isRunning = false;
  int? _startEpochMs;
  String? _uid;
  String? _gymId;
  Timer? _ticker;
  final StreamController<Duration> _tickCtrl = StreamController.broadcast();

  WorkoutSessionDurationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance {
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
  }

  Future<StopResult> stopAndPrompt(BuildContext context) async {
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
    final dayKey = logicDayKey(start.toUtc());

    // query logs for existing sessionId
    String? sessionId;
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

    await metaRef.set({
      'sessionId': sessionId,
      'uid': uid,
      'gymId': gymId,
      'startTime': Timestamp.fromDate(start),
      'endTime': Timestamp.fromDate(end),
      'durationMs': durationMs,
      'dayKey': dayKey,
      'tz': tz,
      'status': 'saved',
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _clearLocal();
  }

  Future<void> discard() async {
    if (!_isRunning) return;
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
}


