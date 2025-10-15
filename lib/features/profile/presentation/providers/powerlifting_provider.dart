// lib/features/profile/presentation/providers/powerlifting_provider.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tapem/core/logging/firestore_read_logger.dart';
import 'package:tapem/features/device/domain/models/device.dart';
import 'package:tapem/features/device/domain/models/exercise.dart';
import 'package:tapem/features/device/domain/usecases/get_devices_for_gym.dart';
import 'package:tapem/features/device/domain/usecases/get_exercises_for_device.dart';
import 'package:tapem/features/profile/domain/models/powerlifting_assignment.dart';
import 'package:tapem/features/profile/domain/models/powerlifting_discipline.dart';
import 'package:tapem/features/profile/domain/models/powerlifting_record.dart';
import 'package:tapem/services/membership_service.dart';

enum PowerliftingMetric {
  heaviest,
  e1rm,
}

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
  /// Assignments rarely change; reuse results for a short time window to avoid
  /// repeatedly fetching the same aggregates during hot restarts.
  final Duration _assignmentCacheTtl = const Duration(minutes: 5);

  String? _userId;
  String? _activeGymId;

  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  DateTime? _lastAssignmentsFetch;

  final Map<PowerliftingDiscipline, List<PowerliftingAssignment>> _assignments = {
    for (final d in PowerliftingDiscipline.values) d: <PowerliftingAssignment>[],
  };

  final Map<PowerliftingDiscipline,
          Map<PowerliftingMetric, List<PowerliftingRecord>>> _records = {
    for (final d in PowerliftingDiscipline.values)
      d: {
        for (final metric in PowerliftingMetric.values)
          metric: <PowerliftingRecord>[],
      },
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

  List<PowerliftingRecord> recordsFor(
    PowerliftingDiscipline discipline, {
    PowerliftingMetric metric = PowerliftingMetric.heaviest,
  }) =>
      List.unmodifiable(_records[discipline]?[metric] ?? const []);

  @override
  void dispose() {
    super.dispose();
  }

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

  Future<void> loadAssignments({bool force = false}) async {
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
      // Avoid hammering Firestore with identical reads during quick rebuilds –
      // the aggregated per-assignment documents update at most a few times per
      // session, so a short cache window is sufficient.
      if (!force &&
          _lastAssignmentsFetch != null &&
          DateTime.now().difference(_lastAssignmentsFetch!) <
              _assignmentCacheTtl &&
          hasAssignments) {
        _isLoading = false;
        notifyListeners();
        return;
      }
      final assignmentsQuery = _firestore
          .collection('users')
          .doc(uid)
          .collection(_assignmentCollection);
      FirestoreReadLogger.logStart(
        scope: 'profile.powerlifting',
        path: 'users/$uid/$_assignmentCollection',
        operation: 'get',
        reason: 'loadAssignments',
      );
      final snapshot = await assignmentsQuery.get();
      FirestoreReadLogger.logResult(
        scope: 'profile.powerlifting',
        path: 'users/$uid/$_assignmentCollection',
        count: snapshot.size,
        fromCache: snapshot.metadata.isFromCache,
      );

      _resetAssignmentsAndRecords();

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

      // Aggregated Cloud Function snapshots contain the user's best lifts per
      // assignment, so we can populate the provider without opening dozens of
      // log streams.
      await _composeRecordsFromAggregates();
      _lastAssignmentsFetch = DateTime.now();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (_userId == null || _activeGymId == null) return;
    await loadAssignments(force: true);
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

      await _reloadAssignmentAggregate(assignment);
      await _composeRecordsFromAggregates();
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
    _resetAssignmentsAndRecords();
    _deviceCache.clear();
    _exerciseCache.clear();
    _error = null;
    _isLoading = false;
    _isSaving = false;
    notifyListeners();
  }

  Future<bool> clearAssignments() async {
    final uid = _userId;
    final gymId = _activeGymId;
    if (uid == null || uid.isEmpty || gymId == null || gymId.isEmpty) {
      return false;
    }

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      await _membership.ensureMembership(gymId, uid);
      final collection = _firestore
          .collection('users')
          .doc(uid)
          .collection(_assignmentCollection);
      FirestoreReadLogger.logStart(
        scope: 'profile.powerlifting',
        path: collection.path,
        operation: 'get',
        reason: 'clearAssignments',
      );
      final snapshot = await collection.get();
      FirestoreReadLogger.logResult(
        scope: 'profile.powerlifting',
        path: collection.path,
        count: snapshot.size,
        fromCache: snapshot.metadata.isFromCache,
      );

      if (snapshot.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      _resetAssignmentsAndRecords();
      _deviceCache.clear();
      _exerciseCache.clear();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> _composeRecordsFromAggregates() async {
    for (final discipline in PowerliftingDiscipline.values) {
      final assignments = _assignments[discipline]!;
      if (assignments.isEmpty) {
        _records[discipline] = _createEmptyRecordMap();
        continue;
      }

      final heaviest = <PowerliftingRecord>[];
      final e1rm = <PowerliftingRecord>[];
      final seenHeaviest = <String>{};
      final seenE1rm = <String>{};

      for (final assignment in assignments) {
        final summary = assignment.latestRecords;
        if (summary == null) {
          continue;
        }

        final labels = await _resolveLabels(
          assignment.gymId,
          assignment.deviceId,
          assignment.exerciseId,
        );

        for (final entry in summary.heaviest) {
          if (entry.weightKg <= 0 || seenHeaviest.contains(entry.logId)) {
            continue;
          }
          final record = _snapshotToRecord(
            assignment: assignment,
            labels: labels,
            snapshot: entry,
          );
          heaviest.add(record);
          seenHeaviest.add(entry.logId);
        }

        for (final entry in summary.e1rm) {
          if (entry.weightKg <= 0 || seenE1rm.contains(entry.logId)) {
            continue;
          }
          final record = _snapshotToRecord(
            assignment: assignment,
            labels: labels,
            snapshot: entry,
          );
          e1rm.add(record);
          seenE1rm.add(entry.logId);
        }
      }

      if (heaviest.isEmpty && e1rm.isEmpty) {
        _records[discipline] = _createEmptyRecordMap();
        continue;
      }

      heaviest.sort((a, b) {
        final weightCompare = b.weightKg.compareTo(a.weightKg);
        if (weightCompare != 0) return weightCompare;
        return b.performedAt.compareTo(a.performedAt);
      });

      e1rm.sort((a, b) {
        final e1rmCompare = b.e1rm.compareTo(a.e1rm);
        if (e1rmCompare != 0) return e1rmCompare;
        return b.performedAt.compareTo(a.performedAt);
      });

      _records[discipline] = {
        PowerliftingMetric.heaviest: heaviest,
        PowerliftingMetric.e1rm: e1rm,
      };
    }
  }

  Future<void> _reloadAssignmentAggregate(
    PowerliftingAssignment assignment,
  ) async {
    final uid = _userId;
    if (uid == null || uid.isEmpty) {
      return;
    }

    final ref = _firestore
        .collection('users')
        .doc(uid)
        .collection(_assignmentCollection)
        .doc(assignment.id);

    FirestoreReadLogger.logStart(
      scope: 'profile.powerlifting',
      path: ref.path,
      operation: 'get',
      reason: 'reloadAssignmentAggregate',
    );
    final snapshot = await ref.get();
    FirestoreReadLogger.logResult(
      scope: 'profile.powerlifting',
      path: ref.path,
      exists: snapshot.exists,
      fromCache: snapshot.metadata.isFromCache,
    );

    if (!snapshot.exists) {
      return;
    }

    final data = snapshot.data() ?? <String, dynamic>{};
    final updated = PowerliftingAssignment.fromMap(snapshot.id, {
      ...data,
      'createdAt': (data['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
    });

    final entries = _assignments[assignment.discipline];
    if (entries == null) {
      return;
    }

    final index = entries.indexWhere((a) => a.id == assignment.id);
    if (index < 0) {
      return;
    }

    entries[index] = updated;
  }

  Map<PowerliftingMetric, List<PowerliftingRecord>> _createEmptyRecordMap() => {
        for (final metric in PowerliftingMetric.values) metric: <PowerliftingRecord>[],
      };

  PowerliftingRecord _snapshotToRecord({
    required PowerliftingAssignment assignment,
    required _PowerliftingLabels labels,
    required PowerliftingLogSnapshot snapshot,
  }) {
    return PowerliftingRecord(
      id: snapshot.logId,
      discipline: assignment.discipline,
      weightKg: snapshot.weightKg,
      reps: snapshot.reps,
      performedAt: snapshot.performedAt,
      deviceName: labels.deviceName,
      exerciseName: labels.exerciseName,
    );
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

  void _resetAssignmentsAndRecords() {
    for (final discipline in PowerliftingDiscipline.values) {
      _assignments[discipline] = <PowerliftingAssignment>[];
      _records[discipline] = _createEmptyRecordMap();
    }
    _lastAssignmentsFetch = null;
  }
}

class _PowerliftingLabels {
  _PowerliftingLabels({required this.deviceName, this.exerciseName});

  final String deviceName;
  final String? exerciseName;
}
