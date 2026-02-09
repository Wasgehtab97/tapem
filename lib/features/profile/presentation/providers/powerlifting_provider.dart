// lib/features/profile/presentation/providers/powerlifting_provider.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/auth_providers.dart' hide gymProvider;
import 'package:tapem/core/providers/gym_provider.dart';
import 'package:tapem/core/providers/gym_scoped_resettable.dart';
import 'package:tapem/features/device/domain/models/device.dart';
import 'package:tapem/features/device/domain/models/exercise.dart';
import 'package:tapem/features/device/domain/usecases/get_devices_for_gym.dart';
import 'package:tapem/features/device/domain/usecases/get_exercises_for_device.dart';
import 'package:tapem/features/profile/domain/models/powerlifting_assignment.dart';
import 'package:tapem/features/profile/domain/models/powerlifting_discipline.dart';
import 'package:tapem/features/profile/domain/models/powerlifting_record.dart';
import 'package:tapem/features/device/providers/device_riverpod.dart';
import 'package:tapem/services/membership_service.dart';

enum PowerliftingMetric { heaviest, e1rm }

class PowerliftingProvider extends ChangeNotifier
    with GymScopedResettableChangeNotifier {
  PowerliftingProvider({
    required FirebaseFirestore firestore,
    required GetDevicesForGym getDevicesForGym,
    required GetExercisesForDevice getExercisesForDevice,
    required MembershipService membership,
  }) : _firestore = firestore,
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

  final Map<PowerliftingDiscipline, List<PowerliftingAssignment>> _assignments =
      {
        for (final d in PowerliftingDiscipline.values)
          d: <PowerliftingAssignment>[],
      };

  final Map<
    PowerliftingDiscipline,
    Map<PowerliftingMetric, List<PowerliftingRecord>>
  >
  _records = {
    for (final d in PowerliftingDiscipline.values)
      d: {
        for (final metric in PowerliftingMetric.values)
          metric: <PowerliftingRecord>[],
      },
  };

  final Map<String, Device> _deviceCache = <String, Device>{};
  final Map<String, List<Exercise>> _exerciseCache = <String, List<Exercise>>{};
  final Set<String> _loadingExercises = <String>{};
  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
  _logSubscriptions =
      <String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>{};

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  String? get activeGymId => _activeGymId;
  bool get hasAssignments =>
      _assignments.values.any((entries) => entries.isNotEmpty);

  List<PowerliftingAssignment> assignmentsFor(
    PowerliftingDiscipline discipline,
  ) => List.unmodifiable(_assignments[discipline]!);

  List<PowerliftingRecord> recordsFor(
    PowerliftingDiscipline discipline, {
    PowerliftingMetric metric = PowerliftingMetric.heaviest,
  }) => List.unmodifiable(_records[discipline]?[metric] ?? const []);

  @override
  void dispose() {
    _disposeLogSubscriptions();
    disposeGymScopedRegistration();
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

  @override
  void resetGymScopedState() {
    _userId = null;
    _activeGymId = null;
    _clearState();
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

      _resetAssignmentsAndRecords();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        final assignment = PowerliftingAssignment.fromMap(doc.id, {
          ...data,
          'createdAt': createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
        });
        if (assignment.gymId != gymId) {
          continue;
        }
        if (assignment.gymId.isEmpty || assignment.deviceId.isEmpty) {
          continue;
        }
        _assignments[assignment.discipline]!.add(assignment);
      }

      for (final entries in _assignments.values) {
        entries.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      }

      await _loadRecordsForAllDisciplines();
      _setupLogSubscriptions();
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

      _assignments[discipline] = <PowerliftingAssignment>[
        ..._assignments[discipline]!,
        assignment,
      ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      await _loadRecordsForDiscipline(discipline);
      _ensureLogSubscription(assignment);
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
    return _loadExercisesForDeviceInGym(gymId, deviceId, cacheKey: cacheKey);
  }

  Future<List<Exercise>> _loadExercisesForDeviceInGym(
    String gymId,
    String deviceId, {
    String? cacheKey,
  }) async {
    final uid = _userId;
    if (gymId.isEmpty || uid == null || uid.isEmpty) {
      return <Exercise>[];
    }

    final resolvedCacheKey = cacheKey ?? '$gymId|$deviceId';
    if (_exerciseCache.containsKey(resolvedCacheKey) &&
        _exerciseCache[resolvedCacheKey]!.isNotEmpty) {
      return _exerciseCache[resolvedCacheKey]!;
    }

    if (_loadingExercises.contains(resolvedCacheKey)) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      return _loadExercisesForDeviceInGym(
        gymId,
        deviceId,
        cacheKey: resolvedCacheKey,
      );
    }

    _loadingExercises.add(resolvedCacheKey);
    try {
      await _membership.ensureMembership(gymId, uid);
      final exercises = await _getExercisesForDevice.execute(
        gymId,
        deviceId,
        uid,
      );
      exercises.sort((a, b) => a.name.compareTo(b.name));
      _exerciseCache[resolvedCacheKey] = exercises;
      return exercises;
    } finally {
      _loadingExercises.remove(resolvedCacheKey);
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
      final snapshot = await collection.where('gymId', isEqualTo: gymId).get();

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

  Future<void> _loadRecordsForAllDisciplines() async {
    for (final discipline in PowerliftingDiscipline.values) {
      await _loadRecordsForDiscipline(discipline);
    }
  }

  Map<PowerliftingMetric, List<PowerliftingRecord>> _createEmptyRecordMap() => {
    for (final metric in PowerliftingMetric.values)
      metric: <PowerliftingRecord>[],
  };

  Future<void> _reloadDisciplineRecords(
    PowerliftingDiscipline discipline,
  ) async {
    await _loadRecordsForDiscipline(discipline);
    notifyListeners();
  }

  Future<void> _loadRecordsForDiscipline(
    PowerliftingDiscipline discipline,
  ) async {
    final entries = _assignments[discipline]!;
    if (entries.isEmpty) {
      _records[discipline] = _createEmptyRecordMap();
      return;
    }

    final futures = entries.map(_fetchRecordsForAssignment);
    final results = await Future.wait(futures);
    final combined = results.expand((element) => element).toList();
    combined.removeWhere((record) => record.weightKg <= 0);
    if (combined.isEmpty) {
      _records[discipline] = _createEmptyRecordMap();
      return;
    }

    final sortedByDate = List<PowerliftingRecord>.from(combined)
      ..sort((a, b) => a.performedAt.compareTo(b.performedAt));

    final heaviest = <PowerliftingRecord>[];
    final e1rm = <PowerliftingRecord>[];
    var bestWeight = -double.infinity;
    var bestE1rm = -double.infinity;
    for (final record in sortedByDate) {
      if (record.weightKg > bestWeight) {
        heaviest.add(record);
        bestWeight = record.weightKg;
      }

      final recordE1rm = record.e1rm;
      if (recordE1rm > bestE1rm) {
        e1rm.add(record);
        bestE1rm = recordE1rm;
      }
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

    final baseQuery = logsCollection
        .where('userId', isEqualTo: uid)
        .where('exerciseId', isEqualTo: assignment.exerciseId);

    final Map<String, QueryDocumentSnapshot<Map<String, dynamic>>> docs =
        <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};

    Future<void> collect(Query<Map<String, dynamic>> query) async {
      final snapshot = await query.get();
      for (final doc in snapshot.docs) {
        docs[doc.id] = doc;
      }
    }

    try {
      await collect(
        baseQuery
            .orderBy('weight', descending: true)
            .orderBy('timestamp', descending: true)
            .limit(_logsLimitPerSource),
      );
    } on FirebaseException catch (error) {
      if (error.code != 'failed-precondition') rethrow;
    }

    await collect(
      baseQuery
          .orderBy('timestamp', descending: true)
          .limit(_logsLimitPerSource),
    );

    if (docs.isEmpty) {
      return <PowerliftingRecord>[];
    }

    final records = <PowerliftingRecord>[];
    for (final doc in docs.values) {
      final data = doc.data();
      final weight = (data['weight'] as num?)?.toDouble() ?? 0;
      final reps = (data['reps'] as num?)?.toInt() ?? 0;
      final timestamp =
          (data['timestamp'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0);

      final record = PowerliftingRecord(
        id: doc.id,
        discipline: assignment.discipline,
        weightKg: weight,
        reps: reps,
        performedAt: timestamp,
        deviceName: labels.deviceName,
        exerciseName: labels.exerciseName,
      );

      records.add(record);
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
      final exercises = await _loadExercisesForDeviceInGym(gymId, deviceId);
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

    return _PowerliftingLabels(
      deviceName: deviceName,
      exerciseName: exerciseName,
    );
  }

  Future<Device?> _loadDevice(String gymId, String deviceId) async {
    final devices = await _getDevicesForGym.execute(gymId);
    for (final device in devices) {
      _deviceCache['$gymId|${device.uid}'] = device;
    }
    return _deviceCache['$gymId|$deviceId'];
  }

  void _resetAssignmentsAndRecords() {
    _disposeLogSubscriptions();
    for (final discipline in PowerliftingDiscipline.values) {
      _assignments[discipline] = <PowerliftingAssignment>[];
      _records[discipline] = _createEmptyRecordMap();
    }
  }

  void _setupLogSubscriptions() {
    for (final discipline in PowerliftingDiscipline.values) {
      for (final assignment in _assignments[discipline]!) {
        _ensureLogSubscription(assignment);
      }
    }
  }

  void _ensureLogSubscription(PowerliftingAssignment assignment) {
    final uid = _userId;
    if (uid == null || uid.isEmpty) {
      return;
    }

    if (_logSubscriptions.containsKey(assignment.id)) {
      return;
    }

    final logsCollection = _firestore
        .collection('gyms')
        .doc(assignment.gymId)
        .collection('devices')
        .doc(assignment.deviceId)
        .collection('logs');

    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? subscription;

    void listenTo(
      Query<Map<String, dynamic>> query, {
      required bool allowFallback,
    }) {
      final currentSubscription = query.snapshots().listen(
        (_) => unawaited(_reloadDisciplineRecords(assignment.discipline)),
        onError: (Object error, StackTrace stackTrace) {
          if (allowFallback && error is FirebaseException) {
            final previous = subscription;
            subscription = null;
            unawaited(previous?.cancel());
            final fallbackQuery = logsCollection
                .where('userId', isEqualTo: uid)
                .where('exerciseId', isEqualTo: assignment.exerciseId)
                .orderBy('timestamp', descending: true)
                .limit(_logsLimitPerSource);
            listenTo(fallbackQuery, allowFallback: false);
          } else if (!allowFallback && error is FirebaseException) {
            final previous = subscription;
            subscription = null;
            unawaited(previous?.cancel());
            _logSubscriptions.remove(assignment.id);
          }
        },
      );
      subscription = currentSubscription;
      _logSubscriptions[assignment.id] = currentSubscription;
    }

    final primaryQuery = logsCollection
        .where('userId', isEqualTo: uid)
        .where('exerciseId', isEqualTo: assignment.exerciseId)
        .orderBy('weight', descending: true)
        .orderBy('timestamp', descending: true)
        .limit(1);

    listenTo(primaryQuery, allowFallback: true);
  }

  void _disposeLogSubscriptions() {
    for (final entry in _logSubscriptions.values) {
      unawaited(entry.cancel());
    }
    _logSubscriptions.clear();
  }
}

final powerliftingProvider = ChangeNotifierProvider<PowerliftingProvider>((
  ref,
) {
  final provider = PowerliftingProvider(
    firestore: FirebaseFirestore.instance,
    getDevicesForGym: ref.read(getDevicesForGymProvider),
    getExercisesForDevice: ref.read(getExercisesForDeviceProvider),
    membership: ref.read(membershipServiceProvider),
  );

  provider.registerGymScopedResettable(
    ref.read(gymScopedStateControllerProvider),
  );

  Future<void> update() {
    final auth = ref.read(authControllerProvider);
    final gym = ref.read(gymProvider);
    return provider.updateContext(userId: auth.userId, gymId: gym.currentGymId);
  }

  ref.onDispose(provider.dispose);
  ref.listen<AuthProvider>(authControllerProvider, (_, __) {
    unawaited(update());
  });
  ref.listen<GymProvider>(gymProvider, (_, __) {
    unawaited(update());
  });
  unawaited(update());
  return provider;
});

class _PowerliftingLabels {
  _PowerliftingLabels({required this.deviceName, this.exerciseName});

  final String deviceName;
  final String? exerciseName;
}
