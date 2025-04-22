// lib/screens/dashboard/dashboard_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/api_services.dart';

/// Ein einzelner Satz.
class SetData {
  final int setNumber;
  final String weight;
  final int reps;

  bool get isComplete => weight.isNotEmpty && reps > 0;

  const SetData({
    required this.setNumber,
    this.weight = '',
    this.reps = 0,
  });

  SetData copyWith({String? weight, int? reps}) =>
      SetData(
        setNumber: setNumber,
        weight: weight ?? this.weight,
        reps: reps ?? this.reps,
      );
}

/// Eine komplette Trainingseinheit.
class SessionData {
  final String? userId;
  final String? deviceId;
  final String exercise;
  final Timestamp trainingDate;
  final List<SetData> sets;

  const SessionData({
    this.userId,
    this.deviceId,
    required this.exercise,
    required this.trainingDate,
    required this.sets,
  });

  factory SessionData.fromMap(Map<String, dynamic> m) {
    return SessionData(
      userId: m['user_id'] as String?,
      deviceId: m['device_id'] as String?,
      exercise: m['exercise'] as String? ?? '',
      trainingDate: m['training_date'] as Timestamp,
      sets: (m['data'] as List<dynamic>).map((d) {
        final map = d as Map<String, dynamic>;
        return SetData(
          setNumber: map['sets'] as int,
          weight: (map['weight'] as num).toString(),
          reps: map['reps'] as int,
        );
      }).toList(),
    );
  }
}

class DashboardController extends ChangeNotifier {
  final ApiService _api = ApiService();

  String? userId;
  String? deviceId;
  Map<String, dynamic>? deviceInfo;

  bool isLoading = true;
  bool showFeedback = false;

  Timestamp _lastTs = Timestamp.now();
  DateTime get trainingDate =>
      _lastTs.toDate().toUtc().add(const Duration(hours: 1));

  // Standard‑Übungen (nur für mode 'multi')
  final List<String> _defaults = ['Benchpress', 'Squat', 'Deadlift'];
  List<String> exerciseOptions = [];

  String? selectedExercise;
  List<SetData> sets = [const SetData(setNumber: 1)];
  SessionData? lastSession;

  DashboardController() {
    // init mit Defaults, wird je nach Mode angepasst
    exerciseOptions = List.from(_defaults);
  }

  /// Lädt Gerätedaten, custom Exercises und letzte Session.
  Future<void> loadDevice(String id, {String? secretCode}) async {
    _setLoading(true);

    // User-ID setzen
    userId = _api.auth.currentUser?.uid;

    // Gerät per Secret oder ID laden
    final dev = secretCode != null
        ? await _api.getDeviceBySecret(id, secretCode)
        : (await _api.getDevices()).firstWhere(
            (d) => d['id'].toString() == id,
            orElse: () => {},
          );

    if (dev == null || dev.isEmpty) {
      _setLoading(false);
      return;
    }

    deviceId = dev['id'].toString();
    deviceInfo = dev;

    final mode = (dev['exercise_mode'] as String).toLowerCase();
    if (mode == 'single') {
      // Nur die eine Übung
      selectedExercise = dev['name'] as String?;
      exerciseOptions = [selectedExercise!];
    } else if (mode == 'multi') {
      // Multi: Standard‑Übungen
      exerciseOptions = List.from(_defaults);
    } else if (mode == 'custom') {
      // Custom: zunächst leer
      exerciseOptions.clear();
    }

    // Custom‑Übungen laden
    await _loadCustomExercises();
    // letzte Session laden
    await _loadLastSession();

    _setLoading(false);
  }

  /// Lädt eigene Übungen aus Firestore
  Future<void> _loadCustomExercises() async {
    if (userId == null || deviceId == null) return;
    try {
      final customs = await _api.getCustomExercises(userId!, deviceId!);
      final names = customs.map((e) => e['name'] as String).toList();
      if (deviceInfo?['exercise_mode'] == 'custom') {
        // Nur eigene Übungen
        exerciseOptions = names;
      } else {
        // Defaults (bei multi) und eigene zusammenführen
        exerciseOptions = [
          ..._defaults.where((d) => exerciseOptions.contains(d)),
          ...names,
        ];
      }
    } catch (_) {
      // bei Fehlern keine Änderung
    }
    notifyListeners();
  }

  /// Fügt eine eigene Übung hinzu (für mode 'custom')
  Future<void> addCustomExercise(String name) async {
    if (userId == null || deviceId == null) return;
    await _api.createCustomExercise(userId!, deviceId!, name);
    await _loadCustomExercises();
    await selectExercise(name);
  }

  /// Setzt die ausgewählte Übung und lädt letzte Session
  Future<void> selectExercise(String ex) async {
    selectedExercise = ex;
    await _loadLastSession();
    notifyListeners();
  }

  /// Aktualisiert ein Set
  void updateSet(int idx, {String? weight, int? reps}) {
    sets[idx] = sets[idx].copyWith(weight: weight, reps: reps);
    notifyListeners();
  }

  /// Fügt einen neuen Satz hinzu
  void addSet() {
    if (!sets.last.isComplete) return;
    sets.add(SetData(setNumber: sets.length + 1));
    notifyListeners();
  }

  /// Speichert die Session in Firestore
  Future<void> finishSession() async {
    if (userId == null || deviceId == null) return;
    final ex = selectedExercise ??
        (deviceInfo?['name'] as String? ?? 'Gerät $deviceId');
    final data = sets
        .where((s) => s.isComplete)
        .map((s) => {
              'exercise': ex,
              'sets': s.setNumber,
              'weight': double.tryParse(s.weight.replaceAll(',', '.')) ?? 0.0,
              'reps': s.reps,
            })
        .toList();
    if (data.isEmpty) return;

    _setLoading(true);
    _lastTs = Timestamp.now();

    final payload = {
      'user_id': userId,
      'device_id': deviceId,
      'exercise': ex,
      'training_date': _lastTs,
      'data': data,
    };
    await _api.postTrainingSession(userId!, payload);

    lastSession = SessionData.fromMap(payload);
    sets = [const SetData(setNumber: 1)];
    _setLoading(false);
  }

  /// Lädt die letzte Session
  Future<void> _loadLastSession() async {
    if (userId == null || deviceId == null) return;
    _setLoading(true);
    try {
      final hist = await _api.getTrainingSessions(
        userId: userId!,
        deviceId: deviceId,
        exercise: selectedExercise,
      );
      if (hist.isNotEmpty) {
        lastSession = SessionData.fromMap(hist.first);
        _lastTs = lastSession!.trainingDate;
      } else {
        lastSession = null;
      }
    } catch (_) {
      lastSession = null;
    }
    _setLoading(false);
  }

  /// Umschalten Feedback-Formular
  void toggleFeedback() {
    showFeedback = !showFeedback;
    notifyListeners();
  }

  void _setLoading(bool v) {
    isLoading = v;
    notifyListeners();
  }
}
