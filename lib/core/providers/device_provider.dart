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
      notifyListeners();

      await _loadLastSession(gymId, deviceId, exerciseId, userId);
      await _loadUserNote(gymId, deviceId, userId);
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

  void setNote(String text) {
    _note = text;
    notifyListeners();
  }

  /// Speichert die Session-Logs, die User-Note und updated das Leaderboard
  Future<void> saveWorkoutSession({
    required String gymId,
    required String userId,
    required bool showInLeaderboard,
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
      if (lastDay == today) {
        throw Exception('Heute bereits gespeichert.');
      }
    }

    final sessionId = _uuid.v4();
    final ts = Timestamp.now();
    final batch = _firestore.batch();
    final savedSets = List<Map<String, String>>.from(_sets);

    // Workout-Logs schreiben
    for (var set in savedSets) {
      final logDoc =
          _firestore
              .collection('gyms')
              .doc(gymId)
              .collection('devices')
              .doc(_device!.uid)
              .collection('logs')
              .doc();
      final data = <String, dynamic>{
        'userId': userId,
        'exerciseId': _currentExerciseId,
        'sessionId': sessionId,
        'timestamp': ts,
        'weight': int.parse(set['weight']!),
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
        await _updateLeaderboard(gymId, userId, showInLeaderboard);
      } catch (e, st) {
        debugPrintStack(label: '_updateLeaderboard', stackTrace: st);
      }
    }

    // Lokalen State zurücksetzen
    _lastSessionSets = savedSets;
    _lastSessionDate = ts.toDate();
    _lastSessionNote = _note;
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
        .collection('leaderboard')
        .doc(userId);
    final sessionRef = lbRef
        .collection('dailySessions')
        .doc('${deviceId}_$dateStr');

    await _firestore.runTransaction((tx) async {
      final lbSnap = await tx.get(lbRef);
      final sessSnap = await tx.get(sessionRef);

      if (!lbSnap.exists) {
        tx.set(lbRef, {
          'xp': 0,
          'showInLeaderboard': showInLeaderboard,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      if (!sessSnap.exists) {
        tx.set(sessionRef, {'deviceId': deviceId, 'date': dateStr});
        tx.update(lbRef, {
          'xp': FieldValue.increment(1),
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

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
