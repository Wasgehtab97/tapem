// lib/core/providers/device_provider.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapem/features/device/data/repositories/device_repository_impl.dart';
import 'package:tapem/features/device/data/sources/firestore_device_source.dart';
import 'package:tapem/features/device/domain/models/device.dart';
import 'package:tapem/features/device/domain/usecases/get_devices_for_gym.dart';
import 'package:uuid/uuid.dart';
import 'package:tapem/features/rank/domain/models/level_info.dart';
import 'package:tapem/features/rank/domain/services/level_service.dart';

class DeviceProvider extends ChangeNotifier {
  final GetDevicesForGym _getDevicesForGym;
  final FirebaseFirestore _firestore;
  final Uuid _uuid = const Uuid();

  List<Device> _devices = [];

  Device? _device;
  bool _isLoading = false;
  String? _error;

  List<Map<String, String>> _sets = [];
  String _note = '';

  List<Map<String, String>> _lastSessionSets = [];
  DateTime? _lastSessionDate;
  String _lastSessionNote = '';
  String? _lastSessionId;
  bool _editingLastSession = false;
  int _xp = 0;
  int _level = 1;

  late String _currentExerciseId;

  DeviceProvider({
    GetDevicesForGym? getDevicesForGym,
    FirebaseFirestore? firestore,
  }) : _getDevicesForGym =
           getDevicesForGym ??
           GetDevicesForGym(DeviceRepositoryImpl(FirestoreDeviceSource())),
       _firestore = firestore ?? FirebaseFirestore.instance;

  // Öffentliche Getter
  bool get isLoading => _isLoading;
  String? get error => _error;
  Device? get device => _device;
  List<Device> get devices => List.unmodifiable(_devices);
  List<Map<String, String>> get sets => List.unmodifiable(_sets);
  String get note => _note;
  List<Map<String, String>> get lastSessionSets =>
      List.unmodifiable(_lastSessionSets);
  DateTime? get lastSessionDate => _lastSessionDate;
  String get lastSessionNote => _lastSessionNote;
  String? get lastSessionId => _lastSessionId;
  bool get editingLastSession => _editingLastSession;
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

  /// Lädt Gerätedaten, letzte Session und Notiz
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

      // Session initialisieren
      _sets = [
        {
          'number': '1',
          'weight': '',
          'reps': '',
          'rir': '',
          'note': '',
        },
      ];
      _lastSessionSets = [];
      _lastSessionDate = null;
      _lastSessionNote = '';
      _lastSessionId = null;
      _editingLastSession = false;
      notifyListeners();

      await _loadLastSession(gymId, deviceId, exerciseId, userId);
      await _loadUserNote(gymId, deviceId, userId);
      if (!_device!.isMulti) {
        await _loadUserXp(gymId, deviceId, userId);
      }
    } catch (e, st) {
      _error = e.toString();
      debugPrintStack(label: 'DeviceProvider.loadDevice', stackTrace: st);
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
    });
    notifyListeners();
  }

  void updateSet(
    int index, {
    String? weight,
    String? reps,
    String? rir,
    String? note,
  }) {
    final current = Map<String, String>.from(_sets[index]);
    if (weight != null) current['weight'] = weight;
    if (reps != null) current['reps'] = reps;
    if (rir != null) current['rir'] = rir;
    if (note != null) current['note'] = note;
    current['number'] = '${index + 1}';
    _sets[index] = current;
    notifyListeners();
  }

  void removeSet(int index) {
    _sets.removeAt(index);
    for (var i = 0; i < _sets.length; i++) {
      _sets[i]['number'] = '${i + 1}';
    }
    notifyListeners();
  }

  /// Lädt die zuletzt gespeicherte Session in die Eingabefelder
  void startEditLastSession() {
    if (_lastSessionSets.isEmpty) return;
    _sets = [
      for (final set in _lastSessionSets)
        Map<String, String>.from(set),
    ];
    _note = _lastSessionNote;
    _editingLastSession = true;
    notifyListeners();
  }

  void setNote(String text) {
    _note = text;
    notifyListeners();
  }

  /// Speichert die Session-Logs, die User-Note und updated das Leaderboard
  Future<void> saveWorkoutSession({
    required String gymId,
    required String userId,
    required bool showInLeaderboard,
    bool overwrite = false,
  }) async {
    if (_device == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Verhindere doppelte Sessions am selben Tag
    if (_lastSessionDate != null) {
      final lastDay = DateTime(
        _lastSessionDate!.year,
        _lastSessionDate!.month,
        _lastSessionDate!.day,
      );
      if (lastDay == today && !overwrite) {
        throw Exception('Heute bereits gespeichert.');
      }
    }

    final sessionId = overwrite && _lastSessionId != null ? _lastSessionId! : _uuid.v4();
    final ts = Timestamp.now();
    final batch = _firestore.batch();
    final savedSets = List<Map<String, String>>.from(_sets);

    final logsCol = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('devices')
        .doc(_device!.uid)
        .collection('logs');

    if (overwrite && _lastSessionId != null) {
      final existing = await logsCol
          .where('userId', isEqualTo: userId)
          .where('sessionId', isEqualTo: _lastSessionId)
          .get();
      for (final doc in existing.docs) {
        batch.delete(doc.reference);
      }
    }

    // Workout-Logs schreiben
    for (var set in savedSets) {
      final logDoc = logsCol.doc();
      final data = <String, dynamic>{
        'userId': userId,
        'exerciseId': _currentExerciseId,
        'sessionId': sessionId,
        'timestamp': ts,
        'weight': double.parse(set['weight']!.replaceAll(',', '.')),
        'reps': int.parse(set['reps']!),
        'note': _note,
      };
      if (set['rir'] != null && set['rir']!.isNotEmpty) {
        data['rir'] = int.parse(set['rir']!);
      }
      if (set['note'] != null && set['note']!.isNotEmpty) {
        data['setNote'] = set['note'];
      }
      batch.set(logDoc, data);
    }

    // User-Note schreiben
    final noteDoc = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('devices')
        .doc(_device!.uid)
        .collection('userNotes')
        .doc(userId);
    batch.set(noteDoc, {'note': _note, 'updatedAt': ts});

    await batch.commit();

    // Leaderboard aktualisieren, nur bei Einzelgeräten und Opt-in
    if (!_device!.isMulti && showInLeaderboard) {
      try {
        await _updateLeaderboard(
          gymId,
          userId,
          sessionId,
          showInLeaderboard,
        );
        await _loadUserXp(gymId, _device!.uid, userId);
      } catch (e, st) {
        debugPrintStack(label: '_updateLeaderboard', stackTrace: st);
      }
    }

    // Lokalen State zurücksetzen
    _lastSessionSets = savedSets;
    _lastSessionDate = ts.toDate();
    _lastSessionNote = _note;
    _lastSessionId = sessionId;
    _editingLastSession = false;
    _sets = [
      {
        'number': '1',
        'weight': '',
        'reps': '',
        'rir': '',
        'note': '',
      },
    ];
    notifyListeners();
  }

  Future<void> _updateLeaderboard(
    String gymId,
    String userId,
    String sessionId,
    bool showInLeaderboard,
  ) async {
    final now = DateTime.now();
    final dateStr =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    final deviceId = _device!.uid;

    final lbRef = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('devices')
        .doc(deviceId)
        .collection('leaderboard')
        .doc(userId);
    final sessionRef = lbRef
        .collection('sessions')
        .doc(sessionId);

    await _firestore.runTransaction((tx) async {
      final lbSnap = await tx.get(lbRef);
      final sessSnap = await tx.get(sessionRef);

      var info = LevelInfo.fromMap(lbSnap.data());

      if (!lbSnap.exists) {
        tx.set(lbRef, {
          ...info.toMap(),
          'showInLeaderboard': showInLeaderboard,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (!sessSnap.exists) {
        info = LevelService().addXp(info, 50);
        tx.set(sessionRef, {
          'deviceId': deviceId,
          'date': dateStr,
        });
        tx.update(lbRef, {
          'xp': info.xp,
          'level': info.level,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
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
    notifyListeners();
  }

  Future<void> _loadUserNote(
    String gymId,
    String deviceId,
    String userId,
  ) async {
    final userNoteDoc =
        _firestore
            .collection('gyms')
            .doc(gymId)
            .collection('devices')
            .doc(deviceId)
            .collection('userNotes')
            .doc(userId)
            .get();
    if ((await userNoteDoc).exists) {
      final data = (await userNoteDoc).data()!;
      _note = data['note'] as String? ?? '';
      notifyListeners();
    }
  }

  Future<void> _loadUserXp(
    String gymId,
    String deviceId,
    String userId,
  ) async {
    final xpDoc = await _firestore
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
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
