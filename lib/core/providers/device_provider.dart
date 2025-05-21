// lib/core/providers/device_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:tapem/features/device/data/repositories/device_repository_impl.dart';
import 'package:tapem/features/device/data/sources/firestore_device_source.dart';
import 'package:tapem/features/device/domain/models/device.dart';
import 'package:tapem/features/device/domain/usecases/get_devices_for_gym.dart';
import 'package:uuid/uuid.dart';

class DeviceProvider extends ChangeNotifier {
  final GetDevicesForGym _getDevices;
  final FirebaseFirestore _firestore;
  final Uuid _uuid = const Uuid();

  Device? _device;
  bool _isLoading = false;
  String? _error;

  final List<Map<String, String>> _sets = [];
  String _note = '';

  List<Map<String, String>> _lastSessionSets = [];
  DateTime? _lastSessionDate;
  String _lastSessionNote = '';

  DeviceProvider({
    GetDevicesForGym? getDevicesForGym,
    FirebaseFirestore? firestore,
  })  : _getDevices = getDevicesForGym ??
            GetDevicesForGym(DeviceRepositoryImpl(FirestoreDeviceSource())),
        _firestore = firestore ?? FirebaseFirestore.instance;

  bool get isLoading => _isLoading;
  String? get error => _error;
  Device? get device => _device;
  List<Map<String, String>> get sets => List.unmodifiable(_sets);
  String get note => _note;
  List<Map<String, String>> get lastSessionSets =>
      List.unmodifiable(_lastSessionSets);
  DateTime? get lastSessionDate => _lastSessionDate;
  String get lastSessionNote => _lastSessionNote;

  Future<void> loadDevice({
    required String gymId,
    required String deviceId,
    required String userId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1) Gerätedaten laden
      final all = await _getDevices.execute(gymId);
      _device = all.firstWhere((d) => d.id == deviceId);

      // 2) Neue Session initialisieren
      _sets
        ..clear()
        ..add({'number': '1', 'weight': '', 'reps': ''});

      // 3) Letzte Session und Note zurücksetzen
      _lastSessionSets = [];
      _lastSessionDate = null;
      _lastSessionNote = '';
      notifyListeners();

      // 4) Letzte Session & Note laden
      await _loadLastSession(
        gymId: gymId,
        deviceId: deviceId,
        userId: userId,
      );
      await _loadUserNote(
        gymId: gymId,
        deviceId: deviceId,
        userId: userId,
      );
    } catch (e, st) {
      _error = e.toString();
      debugPrintStack(label: 'DeviceProvider.loadDevice', stackTrace: st);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addSet() {
    _sets.add({
      'number': '${_sets.length + 1}',
      'weight': '',
      'reps': '',
    });
    notifyListeners();
  }

  void updateSet(int i, String weight, String reps) {
    _sets[i]['weight'] = weight;
    _sets[i]['reps'] = reps;
    notifyListeners();
  }

  void removeSet(int i) {
    _sets.removeAt(i);
    for (var j = 0; j < _sets.length; j++) {
      _sets[j]['number'] = '${j + 1}';
    }
    notifyListeners();
  }

  void setNote(String text) {
    _note = text;
    notifyListeners();
  }

  Future<void> saveSession({
    required String gymId,
    required String userId,
  }) async {
    if (_device == null) return;

    final today = DateTime.now();
    if (_lastSessionDate != null &&
        _lastSessionDate!.year == today.year &&
        _lastSessionDate!.month == today.month &&
        _lastSessionDate!.day == today.day) {
      throw Exception('Heute wurde bereits gespeichert.');
    }

    final sessionId = _uuid.v4();
    final batch = _firestore.batch();
    final ts = Timestamp.now();
    final savedSets = List<Map<String, String>>.from(_sets);

    // 5) Logs schreiben
    for (var set in savedSets) {
      final doc = _firestore
          .collection('gyms')
          .doc(gymId)
          .collection('devices')
          .doc(_device!.id)
          .collection('logs')
          .doc();
      batch.set(doc, {
        'userId': userId,
        'timestamp': ts,
        'weight': int.parse(set['weight']!),
        'reps': int.parse(set['reps']!),
        'sessionId': sessionId,
        'note': _note,
      });
    }

    // 6) User-Note schreiben
    final noteDoc = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('devices')
        .doc(_device!.id)
        .collection('userNotes')
        .doc(userId);
    batch.set(noteDoc, {
      'note': _note,
      'updatedAt': ts,
    });

    await batch.commit();

    // 7) Lokale Anzeige aktualisieren
    _lastSessionSets = savedSets;
    _lastSessionDate = ts.toDate();
    _lastSessionNote = _note;
    _sets
      ..clear()
      ..add({'number': '1', 'weight': '', 'reps': ''});
    notifyListeners();
  }

  /// Lädt die letzte komplette Session (alle Sets) des Nutzers
  Future<void> _loadLastSession({
    required String gymId,
    required String deviceId,
    required String userId,
  }) async {
    final col = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('devices')
        .doc(deviceId)
        .collection('logs');

    // a) Letzten Log-Eintrag des Users holen
    final lastSnap = await col
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (lastSnap.docs.isEmpty) return;

    final data = lastSnap.docs.first.data();
    final sid = data['sessionId'] as String;
    final ts = (data['timestamp'] as Timestamp).toDate();
    final n = data['note'] as String? ?? '';

    // b) **Jetzt auch hier** nach userId filtern, sonst PERMISSION_DENIED
    final sessionDocs = await col
        .where('userId', isEqualTo: userId)
        .where('sessionId', isEqualTo: sid)
        .orderBy('timestamp')
        .get();

    // c) Zu Map umformen
    _lastSessionSets = sessionDocs.docs.asMap().entries.map((e) {
      final m = e.value.data();
      return {
        'number': '${e.key + 1}',
        'weight': '${m['weight']}',
        'reps': '${m['reps']}',
      };
    }).toList();

    _lastSessionDate = ts;
    _lastSessionNote = n;
    notifyListeners();
  }

  /// Lädt die persistente User-Note (falls vorhanden)
  Future<void> _loadUserNote({
    required String gymId,
    required String deviceId,
    required String userId,
  }) async {
    final snap = await _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('devices')
        .doc(deviceId)
        .collection('userNotes')
        .doc(userId)
        .get();
    if (snap.exists) {
      _note = snap.data()?['note'] as String? ?? '';
      notifyListeners();
    }
  }
}
