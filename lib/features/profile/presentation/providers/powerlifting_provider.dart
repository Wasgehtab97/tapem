// lib/features/profile/presentation/providers/powerlifting_provider.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tapem/features/device/domain/models/device.dart';
import 'package:tapem/features/device/domain/models/exercise.dart';
import 'package:tapem/features/device/domain/usecases/get_devices_for_gym.dart';
import 'package:tapem/features/device/domain/usecases/get_exercises_for_device.dart';
import 'package:tapem/features/profile/domain/models/powerlifting_assignment.dart';
import 'package:tapem/features/profile/domain/models/powerlifting_discipline.dart';
import 'package:tapem/features/profile/domain/models/powerlifting_record.dart';
import 'package:tapem/services/membership_service.dart';

class PowerliftingProvider extends ChangeNotifier {
  PowerliftingProvider({
    required FirebaseFirestore firestore,
    required GetDevicesForGym getDevicesForGym,
    required GetExercisesForDevice getExercisesForDevice,
    required MembershipService membership,
  })  : _firestore = firestore,
        _getDevicesForGym = getDevicesForGym,
        _getExercisesForDevice = getExercisesForDevice,
        _membership = membership;

  final FirebaseFirestore _firestore;
  final GetDevicesForGym _getDevicesForGym;
  final GetExercisesForDevice _getExercisesForDevice;
  final MembershipService _membership;

  static const _assignmentCollection = 'powerlifting_sources';
  static const _logsLimitPerSource = 25;

  String? _userId;
  String? _activeGymId;

  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  final Map<PowerliftingDiscipline, List<PowerliftingAssignment>> _assignments = {
    for (final d in PowerliftingDiscipline.values) d: <PowerliftingAssignment>[],
  };

  final Map<PowerliftingDiscipline, List<PowerliftingRecord>> _records = {
    for (final d in PowerliftingDiscipline.values) d: <PowerliftingRecord>[],
  };

  final Map<String, Device> _deviceCache = <String, Device>{};
  final Map<String, List<Exercise>> _exerciseCache = <String, List<Exercise>>{};
  final Set<String> _loadingExercises = <String>{};

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  String? get activeGymId => _activeGymId;
  bool get hasAssignments =>
      _assignments.values.any((entries) => entries.isNotEmpty);

  List<PowerliftingAssignment> assignmentsFor(PowerliftingDiscipline discipline) =>
      List.unmodifiable(_assignments[discipline]!);

  List<PowerliftingRecord> recordsFor(PowerliftingDiscipline discipline) =>
      List.unmodifiable(_records[discipline]!);

  Future<void> updateContext({
    required String? userId,
    required String? gymId,
  }) async {
    final normalizedGymId = (gymId ?? '').trim();
    if (_userId == userId && _activeGymId == normalizedGymId) {
      return;
    }

    _userId = userId;
    _activeGymId = normalizedGymId.isEmpty ? null : normalizedGymId;

    if (_userId == null || _userId!.isEmpty || _activeGymId == null) {
      _clearState();
      return;
    }

    await loadAssignments();
  }

  Future<void> loadAssignments() async {
    final uid = _userId;
    final gymId = _activeGymId;
    if (uid == null || uid.isEmpty || gymId == null || gymId.isEmpty) {
      _clearState();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _membership.ensureMembership(gymId, uid);
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection(_assignmentCollection)
          .get();

      for (final discipline in PowerliftingDiscipline.values) {
        _assignments[discipline] = <PowerliftingAssignment>[];
        _records[discipline] = <PowerliftingRecord>[];
      }

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        final assignment = PowerliftingAssignment.fromMap(doc.id, {
          ...data,
          'createdAt': createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
        });
        if (assignment.gymId.isEmpty || assignment.deviceId.isEmpty) {
          continue;
        }
        _assignments[assignment.discipline]!.add(assignment);
      }

      for (final entries in _assignments.values) {
        entries.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      }

      await _loadRecordsForAllDisciplines();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (_userId == null || _activeGymId == null) return;
    await loadAssignments();
  }

  Future<bool> addAssignment({
    required PowerliftingDiscipline discipline,
    required String gymId,
    required String deviceId,
    required String exerciseId,
  }) async {
    final uid = _userId;
    if (uid == null || uid.isEmpty) {
      _error = 'USER_MISSING';
      notifyListeners();
      return false;
    }

    final normalizedGymId = gymId.trim();
    final normalizedDeviceId = deviceId.trim();
    final normalizedExerciseId = exerciseId.trim();

    if (normalizedGymId.isEmpty ||
        normalizedDeviceId.isEmpty ||
        normalizedExerciseId.isEmpty) {
      return false;
    }

    final existing = _assignments[discipline]!.any(
      (a) =>
          a.gymId == normalizedGymId &&
          a.deviceId == normalizedDeviceId &&
          a.exerciseId == normalizedExerciseId,
    );
    if (existing) {
      _error = 'POWERLIFTING_DUPLICATE';
      notifyListeners();
      return false;
    }

    final id =
        '${discipline.id}|$normalizedGymId|$normalizedDeviceId|$normalizedExerciseId';

    final assignment = PowerliftingAssignment(
      id: id,
      discipline: discipline,
      gymId: normalizedGymId,
      deviceId: normalizedDeviceId,
      exerciseId: normalizedExerciseId,
      createdAt: DateTime.now(),
    );

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      await _membership.ensureMembership(normalizedGymId, uid);
      await _firestore
          .collection('users')
          .doc(uid)
          .collection(_assignmentCollection)
          .doc(id)
          .set({
        'discipline': assignment.discipline.id,
        'gymId': assignment.gymId,
        'deviceId': assignment.deviceId,
        'exerciseId': assignment.exerciseId,
        'createdAt': Timestamp.fromDate(assignment.createdAt),
      }, SetOptions(merge: true));

      _assignments[discipline] = <PowerliftingAssignment>[...
        _assignments[discipline]!,
        assignment,
      ]
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      await _loadRecordsForDiscipline(discipline);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<List<Device>> loadDevicesForActiveGym() async {
    final gymId = _activeGymId;
    final uid = _userId;
    if (gymId == null || gymId.isEmpty || uid == null || uid.isEmpty) {
      return <Device>[];
    }

    await _membership.ensureMembership(gymId, uid);
    final devices = await _getDevicesForGym.execute(gymId);
    for (final device in devices) {
      _deviceCache['$gymId|${device.uid}'] = device;
    }
    devices.sort((a, b) => a.name.compareTo(b.name));
    return devices;
  }

  Future<List<Exercise>> loadExercisesForDevice(String deviceId) async {
    final gymId = _activeGymId;
    final uid = _userId;
    if (gymId == null || gymId.isEmpty || uid == null || uid.isEmpty) {
      return <Exercise>[];
    }

    final cacheKey = '$gymId|$deviceId';
    if (_exerciseCache.containsKey(cacheKey) &&
        _exerciseCache[cacheKey]!.isNotEmpty) {
      return _exerciseCache[cacheKey]!;
    }

    if (_loadingExercises.contains(cacheKey)) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      return loadExercisesForDevice(deviceId);
    }

    _loadingExercises.add(cacheKey);
    try {
      await _membership.ensureMembership(gymId, uid);
      final exercises =
          await _getExercisesForDevice.execute(gymId, deviceId, uid);
      exercises.sort((a, b) => a.name.compareTo(b.name));
      _exerciseCache[cacheKey] = exercises;
      return exercises;
    } finally {
      _loadingExercises.remove(cacheKey);
    }
  }

  void _clearState() {
    for (final discipline in PowerliftingDiscipline.values) {
      _assignments[discipline] = <PowerliftingAssignment>[];
      _records[discipline] = <PowerliftingRecord>[];
    }
    _deviceCache.clear();
    _exerciseCache.clear();
    _error = null;
    _isLoading = false;
    _isSaving = false;
    notifyListeners();
  }

  Future<void> _loadRecordsForAllDisciplines() async {
    for (final discipline in PowerliftingDiscipline.values) {
      await _loadRecordsForDiscipline(discipline);
    }
  }

  Future<void> _loadRecordsForDiscipline(
    PowerliftingDiscipline discipline,
  ) async {
    final entries = _assignments[discipline]!;
    if (entries.isEmpty) {
      _records[discipline] = <PowerliftingRecord>[];
      return;
    }

    final futures = entries.map(_fetchRecordsForAssignment);
    final results = await Future.wait(futures);
    final combined = results.expand((element) => element).toList();
    combined.sort((a, b) {
      final weightCompare = b.weightKg.compareTo(a.weightKg);
      if (weightCompare != 0) return weightCompare;
      return b.performedAt.compareTo(a.performedAt);
    });
    _records[discipline] = combined;
  }

  Future<List<PowerliftingRecord>> _fetchRecordsForAssignment(
    PowerliftingAssignment assignment,
  ) async {
    final uid = _userId;
    if (uid == null || uid.isEmpty) {
      return <PowerliftingRecord>[];
    }

    final labels = await _resolveLabels(
      assignment.gymId,
      assignment.deviceId,
      assignment.exerciseId,
    );

    final logsCollection = _firestore
        .collection('gyms')
        .doc(assignment.gymId)
        .collection('devices')
        .doc(assignment.deviceId)
        .collection('logs');

    Query<Map<String, dynamic>> query = logsCollection
        .where('userId', isEqualTo: uid)
        .where('exerciseId', isEqualTo: assignment.exerciseId);

    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
    try {
      query = query
          .orderBy('weight', descending: true)
          .orderBy('timestamp', descending: true)
          .limit(_logsLimitPerSource);
      final snapshot = await query.get();
      docs = snapshot.docs;
    } on FirebaseException {
      final snapshot = await logsCollection
          .where('userId', isEqualTo: uid)
          .where('exerciseId', isEqualTo: assignment.exerciseId)
          .orderBy('timestamp', descending: true)
          .limit(_logsLimitPerSource)
          .get();
      docs = snapshot.docs;
    }

    final records = <PowerliftingRecord>[];
    for (final doc in docs) {
      final data = doc.data();
      final weight = (data['weight'] as num?)?.toDouble() ?? 0;
      final reps = (data['reps'] as num?)?.toInt() ?? 0;
      final timestamp = (data['timestamp'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0);

      records.add(
        PowerliftingRecord(
          id: doc.id,
          discipline: assignment.discipline,
          weightKg: weight,
          reps: reps,
          performedAt: timestamp,
          deviceName: labels.deviceName,
          exerciseName: labels.exerciseName,
        ),
      );
    }
    return records;
  }

  Future<_PowerliftingLabels> _resolveLabels(
    String gymId,
    String deviceId,
    String exerciseId,
  ) async {
    final deviceKey = '$gymId|$deviceId';
    Device? device = _deviceCache[deviceKey];
    device ??= await _loadDevice(gymId, deviceId);

    var deviceName = device?.name ?? deviceId;
    String? exerciseName;

    if ((device?.isMulti ?? false) || exerciseId != deviceId) {
      final exercises = await loadExercisesForDevice(deviceId);
      exerciseName = exercises
          .firstWhere(
            (element) => element.id == exerciseId,
            orElse: () => Exercise(
              id: exerciseId,
              name: exerciseId,
              userId: _userId ?? '',
            ),
          )
          .name;
    }

    return _PowerliftingLabels(deviceName: deviceName, exerciseName: exerciseName);
  }

  Future<Device?> _loadDevice(String gymId, String deviceId) async {
    final devices = await _getDevicesForGym.execute(gymId);
    for (final device in devices) {
      _deviceCache['$gymId|${device.uid}'] = device;
    }
    return _deviceCache['$gymId|$deviceId'];
  }
}

class _PowerliftingLabels {
  _PowerliftingLabels({required this.deviceName, this.exerciseName});

  final String deviceName;
  final String? exerciseName;
}
