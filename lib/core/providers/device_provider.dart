// lib/core/providers/device_provider.dart
// Fully instrumented provider with no-op guard and boolean 'done'.
// Fixes re-entrant rebuilds by avoiding notify on unchanged data.

import 'dart:async';
import 'package:flutter/foundation.dart'; // mapEquals

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tapem/features/device/data/repositories/device_repository_impl.dart';
import 'package:tapem/features/device/data/sources/firestore_device_source.dart';
import 'package:tapem/features/device/domain/models/device.dart';
import 'package:tapem/features/device/domain/usecases/get_devices_for_gym.dart';
import 'package:uuid/uuid.dart';
import 'package:tapem/features/rank/domain/models/level_info.dart';
import 'package:tapem/features/rank/domain/services/level_service.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/xp_provider.dart';
import 'package:tapem/core/providers/challenge_provider.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

typedef LogFn = void Function(String message, [StackTrace? stack]);

void _defaultLog(String message, [StackTrace? stack]) {
  if (stack != null) {
    debugPrintStack(label: message, stackTrace: stack);
  } else {
    debugPrint(message);
  }
}

String _setsBrief(List<Map<String, dynamic>> sets) {
  return '[${sets.map((s) => '{#${s['number']}:w=${s['weight']},r=${s['reps']},d=${s['done']}}').join(', ')}]';
}

class DeviceProvider extends ChangeNotifier {
  final GetDevicesForGym _getDevicesForGym;
  final FirebaseFirestore _firestore;
  final LogFn _log;
  final Uuid _uuid = const Uuid();

  List<Device> _devices = [];

  Device? _device;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  List<Map<String, dynamic>> _sets = [];
  String _note = '';

  List<Map<String, String>> _lastSessionSets = [];
  DateTime? _lastSessionDate;
  String _lastSessionNote = '';
  String? _lastSessionId;
  int _xp = 0;
  int _level = 1;

  late String _currentExerciseId;

  DeviceProvider({
    required FirebaseFirestore firestore,
    GetDevicesForGym? getDevicesForGym,
    LogFn? log,
  }) : _firestore = firestore,
       _getDevicesForGym =
           getDevicesForGym ??
           GetDevicesForGym(
             DeviceRepositoryImpl(FirestoreDeviceSource(firestore: firestore)),
           ),
       _log = log ?? _defaultLog;

  // Public getters
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  Device? get device => _device;
  List<Device> get devices => List.unmodifiable(_devices);
  List<Map<String, dynamic>> get sets => List.unmodifiable(_sets);
  String get note => _note;
  List<Map<String, String>> get lastSessionSets =>
      List.unmodifiable(_lastSessionSets);
  DateTime? get lastSessionDate => _lastSessionDate;
  String get lastSessionNote => _lastSessionNote;
  String? get lastSessionId => _lastSessionId;
  bool get hasSessionToday {
    if (_lastSessionDate == null) return false;
    final now = DateTime.now();
    final lastDay = DateTime(
      _lastSessionDate!.year,
      _lastSessionDate!.month,
      _lastSessionDate!.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    return lastDay == today;
  }

  int get xp => _xp;
  int get level => _level;

  Future<void> loadDevices(String gymId) async {
    _devices = await _getDevicesForGym.execute(gymId);
    notifyListeners();
  }

  void patchDeviceGroups(
    String deviceId,
    List<String> primaryGroups,
    List<String> secondaryGroups,
  ) {
    final i = _devices.indexWhere((d) => d.uid == deviceId);
    if (i == -1) return;
    _devices[i] = _devices[i].copyWith(
      primaryMuscleGroups: primaryGroups,
      secondaryMuscleGroups: secondaryGroups,
    );
    notifyListeners();
  }

  void applyMuscleAssignments(
    String deviceId,
    List<String> primaryGroups,
    List<String> secondaryGroups,
  ) {
    patchDeviceGroups(deviceId, primaryGroups, secondaryGroups);
  }

  Future<void> loadDevice({
    required String gymId,
    required String deviceId,
    required String exerciseId,
    required String userId,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final devices = await _getDevicesForGym.execute(gymId);
      _device = devices.firstWhere(
        (d) => d.uid == deviceId,
        orElse: () => throw Exception('Device not found'),
      );
      _currentExerciseId = exerciseId;

      _xp = 0;
      _level = 1;

      _sets = [
        {
          'number': '1',
          'weight': '',
          'reps': '',
          'rir': '',
          'note': '',
          'done': false, // bool statt String
        },
      ];
      _lastSessionSets = [];
      _lastSessionDate = null;
      _lastSessionNote = '';
      _lastSessionId = null;
      _log(
        '🧩 [Provider] loadDevice initialized sets=${_sets.length} ${_setsBrief(_sets)}',
      );
      notifyListeners();

      await _loadLastSession(gymId, deviceId, exerciseId, userId);
      await _loadUserNote(gymId, deviceId, userId);
      if (!_device!.isMulti) {
        await _loadUserXp(gymId, deviceId, userId);
      }
      _log(
        '✅ [Provider] loadDevice done device=${_device!.name} exerciseId=$exerciseId',
      );
    } catch (e, st) {
      _error = e.toString();
      _log('❌ [Provider] loadDevice error: $e', st);
    } finally {
      _setLoading(false);
    }
  }

  void addSet() {
    _sets.add({
      'number': '${_sets.length + 1}',
      'weight': '',
      'reps': '',
      'rir': '',
      'note': '',
      'done': false,
    });
    _log('➕ [Provider] addSet → count=${_sets.length} ${_setsBrief(_sets)}');
    notifyListeners();
  }

  void insertSetAt(int index, Map<String, dynamic> set) {
    _sets.insert(index, Map<String, dynamic>.from(set));
    for (var i = 0; i < _sets.length; i++) {
      _sets[i]['number'] = '${i + 1}';
    }
    _log(
      '↩️ [Provider] insertSetAt($index) → count=${_sets.length} ${_setsBrief(_sets)}',
    );
    notifyListeners();
  }

  void updateSet(
    int index, {
    String? weight,
    String? reps,
    String? rir,
    String? note,
  }) {
    final before = Map<String, dynamic>.from(_sets[index]);
    final after = Map<String, dynamic>.from(before);

    if (weight != null) after['weight'] = weight;
    if (reps != null) after['reps'] = reps;
    if (rir != null) after['rir'] = rir;
    if (note != null) after['note'] = note;

    after['number'] = '${index + 1}';
    after['done'] = (after['done'] == true || after['done'] == 'true');

    if (mapEquals(before, after)) {
      // No-op → kein notify
      return;
    }
    _sets[index] = after;
    _log('✏️ [Provider] updateSet($index) $before → $after');
    notifyListeners();
  }

  void removeSet(int index) {
    final removed = _sets[index];
    _sets.removeAt(index);
    for (var i = 0; i < _sets.length; i++) {
      _sets[i]['number'] = '${i + 1}';
    }
    _log(
      '🗑️ [Provider] removeSet($index) removed=$removed → count=${_sets.length} ${_setsBrief(_sets)}',
    );
    notifyListeners();
  }

  void toggleSetDone(int index) {
    final s = _sets[index];
    final w = (s['weight'] ?? '').toString().trim();
    final r = (s['reps'] ?? '').toString().trim();

    final valid =
        w.isNotEmpty &&
        double.tryParse(w.replaceAll(',', '.')) != null &&
        r.isNotEmpty &&
        int.tryParse(r) != null;

    if (!valid) {
      _error = 'Bitte gültiges Gewicht und Wiederholungen angeben.';
      _log(
        '⚠️ [Provider] toggleSetDone($index) blocked: invalid w="$w" r="$r"',
      );
      notifyListeners();
      return;
    }

    final before = Map<String, dynamic>.from(s);
    final current = (s['done'] == true || s['done'] == 'true');
    s['done'] = !current;
    _sets[index] = Map<String, dynamic>.from(s);
    _log('☑️ [Provider] toggleSetDone($index) $before → ${_sets[index]}');
    notifyListeners();
  }

  int get completedCount =>
      _sets.where((s) => (s['done'] == true || s['done'] == 'true')).length;

  void setNote(String text) {
    _note = text;
    _log('📝 [Provider] setNote "$text"');
    notifyListeners();
  }

  Future<bool> saveWorkoutSession({
    required BuildContext context,
    required String gymId,
    required String userId,
    required bool showInLeaderboard,
  }) async {
    if (_device == null) return false;

    _error = null;
    _isSaving = true;
    _log('💾 [Provider] saveWorkoutSession start sets=${_setsBrief(_sets)}');
    notifyListeners();

    try {
      final savedSets =
          _sets
              .where((s) => (s['done'] == true || s['done'] == 'true'))
              .toList();
      if (savedSets.isEmpty) {
        _error = 'Keine abgeschlossenen Sätze.';
        _log('⚠️ [Provider] save aborted: no completed sets');
        return false;
      }

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final logsCol = _firestore
          .collection('gyms')
          .doc(gymId)
          .collection('devices')
          .doc(_device!.uid)
          .collection('logs');

      final existingToday =
          await logsCol
              .where('userId', isEqualTo: userId)
              .where('exerciseId', isEqualTo: _currentExerciseId)
              .where(
                'timestamp',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
              )
              .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
              .limit(1)
              .get();

      if (existingToday.docs.isNotEmpty) {
        _error = 'Heute bereits gespeichert.';
        _log('⚠️ [Provider] save aborted: already saved today');
        return false;
      }

      final sessionId = _uuid.v4();
      final ts = Timestamp.now();
      String tz;
      try {
        tz = await FlutterTimezone.getLocalTimezone();
      } catch (_) {
        tz = DateTime.now().timeZoneName;
      }
      final batch = _firestore.batch();

      for (final set in savedSets) {
        final ref = logsCol.doc();
        final data = <String, dynamic>{
          'deviceId': _device!.uid,
          'userId': userId,
          'exerciseId': _currentExerciseId,
          'sessionId': sessionId,
          'timestamp': ts,
          'weight': double.parse(set['weight']!.replaceAll(',', '.')),
          'reps': int.parse(set['reps']!),
          'note': _note,
          'tz': tz,
        };
        if ((set['rir'] ?? '').toString().isNotEmpty) {
          data['rir'] = int.parse(set['rir']!);
        }
        if ((set['note'] ?? '').toString().isNotEmpty) {
          data['setNote'] = set['note'];
        }
        batch.set(ref, data);
      }

      final noteRef = _firestore
          .collection('gyms')
          .doc(gymId)
          .collection('devices')
          .doc(_device!.uid)
          .collection('userNotes')
          .doc(userId);
      batch.set(noteRef, {'note': _note, 'updatedAt': ts});

      await batch.commit();
      _log('📚 [Provider] logs stored session=$sessionId');

      try {
        await Provider.of<XpProvider>(context, listen: false).addSessionXp(
          gymId: gymId,
          userId: userId,
          deviceId: _device!.uid,
          sessionId: sessionId,
          showInLeaderboard: showInLeaderboard,
          isMulti: _device!.isMulti,
          primaryMuscleGroupIds: _device!.primaryMuscleGroups,
          tz: tz,
        );
        await Provider.of<ChallengeProvider>(
          context,
          listen: false,
        ).checkChallenges(gymId, userId, _device!.uid);
      } catch (e, st) {
        _log('⚠️ [Provider] XP/Challenges error: $e', st);
      }

      _lastSessionSets = [
        for (final s in savedSets)
          {
            'number': s['number'].toString(),
            'weight': s['weight'].toString(),
            'reps': s['reps'].toString(),
            'rir': (s['rir'] ?? '').toString(),
            'note': (s['note'] ?? '').toString(),
          },
      ];
      _lastSessionDate = ts.toDate();
      _lastSessionNote = _note;
      _lastSessionId = sessionId;

      _sets.removeWhere((s) => (s['done'] == true || s['done'] == 'true'));
      if (_sets.isEmpty) {
        _sets = [
          {
            'number': '1',
            'weight': '',
            'reps': '',
            'rir': '',
            'note': '',
            'done': false,
          },
        ];
      }
      for (var i = 0; i < _sets.length; i++) {
        _sets[i]['number'] = '${i + 1}';
      }

      _log(
        '✅ [Provider] save done. remainingSets=${_setsBrief(_sets)} lastSessionId=$sessionId',
      );
      notifyListeners();
      return true;
    } catch (e, st) {
      _error = e.toString();
      _log('❌ [Provider] saveWorkoutSession error: $e', st);
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> _loadLastSession(
    String gymId,
    String deviceId,
    String exerciseId,
    String userId,
  ) async {
    final logsCol = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('devices')
        .doc(deviceId)
        .collection('logs');

    final lastSnap =
        await logsCol
            .where('userId', isEqualTo: userId)
            .where('exerciseId', isEqualTo: exerciseId)
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();
    if (lastSnap.docs.isEmpty) return;

    final data = lastSnap.docs.first.data();
    final sid = data['sessionId'] as String;
    final ts = (data['timestamp'] as Timestamp).toDate();
    final note = data['note'] as String? ?? '';

    final sessionDocs =
        await logsCol
            .where('userId', isEqualTo: userId)
            .where('exerciseId', isEqualTo: exerciseId)
            .where('sessionId', isEqualTo: sid)
            .orderBy('timestamp')
            .get();

    _lastSessionSets = [
      for (var entry in sessionDocs.docs.asMap().entries)
        {
          'number': '${entry.key + 1}',
          'weight': '${entry.value.data()['weight']}',
          'reps': '${entry.value.data()['reps']}',
          'rir': '${entry.value.data()['rir'] ?? ''}',
          'note': '${entry.value.data()['setNote'] ?? ''}',
        },
    ];
    _lastSessionDate = ts;
    _lastSessionNote = note;
    _lastSessionId = sid;
    _log(
      '📜 [Provider] loaded last session id=$sid sets=${_lastSessionSets.length}',
    );
    notifyListeners();
  }

  Future<void> _loadUserNote(
    String gymId,
    String deviceId,
    String userId,
  ) async {
    final snap =
        await _firestore
            .collection('gyms')
            .doc(gymId)
            .collection('devices')
            .doc(deviceId)
            .collection('userNotes')
            .doc(userId)
            .get();
    if (snap.exists) {
      final data = snap.data()!;
      _note = data['note'] as String? ?? '';
      _log('📝 [Provider] loaded user note "${_note.replaceAll('\n', '\\n')}"');
      notifyListeners();
    }
  }

  Future<void> _loadUserXp(String gymId, String deviceId, String userId) async {
    final xpDoc =
        await _firestore
            .collection('gyms')
            .doc(gymId)
            .collection('devices')
            .doc(deviceId)
            .collection('leaderboard')
            .doc(userId)
            .get();
    if (xpDoc.exists) {
      final data = xpDoc.data()!;
      _xp = data['xp'] as int? ?? 0;
      _level = data['level'] as int? ?? 1;
    } else {
      _xp = 0;
      _level = 1;
    }
    _log('⭐ [Provider] load XP level=$_level xp=$_xp');
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    _log('⏳ [Provider] isLoading=$value');
    notifyListeners();
  }
}
