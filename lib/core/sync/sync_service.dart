import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:tapem/core/database/database_service.dart';
import 'package:tapem/core/sync/models/hive_sync_job.dart';

/// Sync service with Hive-based offline sync queue
class SyncService {
  final DatabaseService _db;
  final FirebaseFirestore _firestore;
  final Connectivity _connectivity;

  StreamSubscription? _connectivitySubscription;
  bool _isSyncing = false;
  Timer? _periodicSyncTimer;

  SyncService(this._db, {FirebaseFirestore? firestore, Connectivity? connectivity})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _connectivity = connectivity ?? Connectivity();

  void init() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        debugPrint('[SyncService] Connectivity restored, triggering sync');
        syncPendingJobs();
      }
    });

    // Start periodic sync every 5 minutes when online
    _periodicSyncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      syncPendingJobs();
    });

    // Initial sync on startup
    Future.delayed(const Duration(seconds: 2), () {
      syncPendingJobs();
    });

    debugPrint('[SyncService] Initialized with Hive');
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _periodicSyncTimer?.cancel();
  }

  Future<void> syncPendingJobs() async {
    if (_isSyncing) {
      debugPrint('[SyncService] Already syncing, skipping');
      return;
    }
    
    _isSyncing = true;

    try {
      final box = _db.syncJobsBox;
      final allJobs = box.values.toList();
      
      // Sort by createdAt and take max 50
      allJobs.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      final jobs = allJobs.take(50).toList();

      debugPrint('[SyncService] Found ${jobs.length} pending jobs');

      for (final job in jobs) {
        // Skip jobs that have exceeded retry limit
        if (job.retryCount >= 5) {
          debugPrint('[SyncService] Job ${job.id} exceeded retry limit, skipping');
          continue;
        }

        // Exponential backoff
        if (job.lastAttempt != null) {
          final backoffMs = min(pow(2, job.retryCount) * 1000, 60000).toInt();
          final elapsed = DateTime.now().difference(job.lastAttempt!).inMilliseconds;
          if (elapsed < backoffMs) {
            continue; // Skip this job for now
          }
        }

        try {
          await _processJob(job);
          debugPrint('[SyncService] Successfully processed job ${job.id}');
          
          // Delete job from Hive
          await job.delete();
        } catch (e) {
          debugPrint('[SyncService] Failed to process job ${job.id}: $e');
          
          // Update retry count and last attempt
          job.retryCount++;
          job.lastAttempt = DateTime.now();
          await job.save();
        }
      }
    } catch (e) {
      debugPrint('[SyncService] Sync error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _processJob(HiveSyncJob job) async {
    final data = jsonDecode(job.payload) as Map<String, dynamic>;
    
    if (job.collection == 'sessions') {
      final gymId = data['gymId'] as String?;
      final deviceId = data['deviceId'] as String?;
      
      if (gymId == null || deviceId == null) {
        throw Exception('Invalid session data: missing gymId or deviceId');
      }

      final sets = (data['sets'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final userId = data['userId'] as String? ?? '';
      final exerciseId = (data['exerciseId'] as String? ?? '').trim();
      final isMulti = data['isMulti'] == true;
      final exerciseName = (data['exerciseName'] as String? ?? '').trim();
      final deviceName = (data['deviceName'] as String? ?? deviceId).trim();
      final deviceDescription = data['deviceDescription'] as String?;
      final sessionTimestamp = DateTime.tryParse(
            data['timestamp'] as String? ?? '',
          ) ??
          DateTime.now();
      
      // Write each set as a separate log entry
      final batch = _firestore.batch();
      for (var i = 0; i < sets.length; i++) {
        final set = sets[i];
        final ref = _firestore
            .collection('gyms')
            .doc(gymId)
            .collection('devices')
            .doc(deviceId)
            .collection('logs')
            .doc();

        batch.set(ref, {
          'sessionId': job.docId,
          'userId': userId,
          'deviceId': deviceId,
          'exerciseId': exerciseId,
          'timestamp': Timestamp.fromDate(sessionTimestamp),
          'weight': set['weight'] ?? 0.0,
          'reps': set['reps'] ?? 0,
          'setNumber': i + 1,
          'dropWeightKg': set['dropWeightKg'] ?? 0.0,
          'dropReps': set['dropReps'] ?? 0,
          'isBodyweight': set['isBodyweight'] ?? false,
          'note': data['note'],
        });
      }

      final bestE1rm = _bestE1rmForSets(sets);
      if (bestE1rm != null && bestE1rm > 0 && userId.isNotEmpty) {
        final progressKey =
            (isMulti && exerciseId.isNotEmpty) ? '$deviceId::$exerciseId' : deviceId;
        final year = sessionTimestamp.year.toString();
        final fallbackTitle =
            exerciseId.isNotEmpty ? exerciseId : deviceName;
        final title = isMulti
            ? (exerciseName.isNotEmpty ? exerciseName : fallbackTitle)
            : deviceName;
        final subtitle = isMulti ? deviceName : (deviceDescription ?? '');

        final progressRef = _firestore
            .collection('gyms')
            .doc(gymId)
            .collection('users')
            .doc(userId)
            .collection('progress')
            .doc(progressKey)
            .collection('years')
            .doc(year);

        final indexRef = _firestore
            .collection('gyms')
            .doc(gymId)
            .collection('users')
            .doc(userId)
            .collection('progressIndex')
            .doc(year);

        final dayKey = _dayKey(sessionTimestamp);
        final point = {
          'sessionId': job.docId,
          'ts': Timestamp.fromDate(sessionTimestamp),
          'e1rm': bestE1rm,
        };

        batch.set(
          progressRef,
          {
            'deviceId': deviceId,
            'exerciseId': exerciseId,
            'isMulti': isMulti,
            'title': title,
            'subtitle': subtitle,
            'year': sessionTimestamp.year,
            'updatedAt': FieldValue.serverTimestamp(),
            'sessionCount': FieldValue.increment(1),
            'pointsByDay.$dayKey': point,
          },
          SetOptions(merge: true),
        );

        batch.set(
          indexRef,
          {
            'year': sessionTimestamp.year,
            'updatedAt': FieldValue.serverTimestamp(),
            'items.$progressKey.deviceId': deviceId,
            'items.$progressKey.exerciseId': exerciseId,
            'items.$progressKey.isMulti': isMulti,
            'items.$progressKey.title': title,
            'items.$progressKey.subtitle': subtitle,
            'items.$progressKey.sessionCount': FieldValue.increment(1),
            'items.$progressKey.lastSessionAt':
                Timestamp.fromDate(sessionTimestamp),
          },
          SetOptions(merge: true),
        );
      }

      if (job.action == 'delete') {
        // For delete, we need to query and delete all sets
        final logsRef = _firestore
            .collection('gyms')
            .doc(gymId)
            .collection('devices')
            .doc(deviceId)
            .collection('logs');
        
        final snapshot = await logsRef
            .where('sessionId', isEqualTo: job.docId)
            .get();
        if (snapshot.docs.isNotEmpty) {
          final firstData = snapshot.docs.first.data();
          final deleteExerciseId =
              (firstData['exerciseId'] as String? ?? '').trim();
          final deleteTimestamp =
              (firstData['timestamp'] as Timestamp?)?.toDate() ??
                  DateTime.now();
          final deleteUserId =
              (firstData['userId'] as String? ?? userId).trim();
          final deleteIsMulti = deleteExerciseId.isNotEmpty;
          final deleteYear = deleteTimestamp.year.toString();
          final deleteDayKey = _dayKey(deleteTimestamp);
          double? deleteBestE1rm;
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final weight = (data['weight'] as num?)?.toDouble() ?? 0.0;
            final reps = (data['reps'] as num?)?.toInt() ?? 0;
            if (weight <= 0 || reps <= 0) continue;
            final e1rm = _calculateE1rm(weight, reps);
            if (deleteBestE1rm == null || e1rm > deleteBestE1rm) {
              deleteBestE1rm = e1rm;
            }
          }

          if (deleteBestE1rm != null &&
              deleteBestE1rm > 0 &&
              deleteUserId.isNotEmpty) {
            final progressKey = deleteIsMulti && deleteExerciseId.isNotEmpty
                ? '$deviceId::$deleteExerciseId'
                : deviceId;
            final progressRef = _firestore
                .collection('gyms')
                .doc(gymId)
                .collection('users')
                .doc(deleteUserId)
                .collection('progress')
                .doc(progressKey)
                .collection('years')
                .doc(deleteYear);

            final indexRef = _firestore
                .collection('gyms')
                .doc(gymId)
                .collection('users')
                .doc(deleteUserId)
                .collection('progressIndex')
                .doc(deleteYear);

            batch.set(
              progressRef,
              {
                'updatedAt': FieldValue.serverTimestamp(),
                'sessionCount': FieldValue.increment(-1),
                'pointsByDay.$deleteDayKey': FieldValue.delete(),
              },
              SetOptions(merge: true),
            );

            batch.set(
              indexRef,
              {
                'updatedAt': FieldValue.serverTimestamp(),
                'items.$progressKey.sessionCount': FieldValue.increment(-1),
              },
              SetOptions(merge: true),
            );
          }
        }

        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
      }

      await batch.commit();
    }
  }

  double? _bestE1rmForSets(List<Map<String, dynamic>> sets) {
    double? best;
    for (final set in sets) {
      final weight = (set['weight'] as num?)?.toDouble() ?? 0.0;
      final reps = (set['reps'] as num?)?.toInt() ?? 0;
      if (weight <= 0 || reps <= 0) continue;
      final e1rm = _calculateE1rm(weight, reps);
      if (best == null || e1rm > best) {
        best = e1rm;
      }
    }
    return best;
  }

  double _calculateE1rm(double weight, int reps) {
    return weight * (1 + reps / 30);
  }

  String _dayKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> addJob({
    required String collection,
    required String docId,
    required String action,
    required Map<String, dynamic> payload,
  }) async {
    final job = HiveSyncJob()
      ..id = const Uuid().v4()
      ..collection = collection
      ..docId = docId
      ..action = action
      ..payload = jsonEncode(payload)
      ..createdAt = DateTime.now()
      ..retryCount = 0;

    await _db.syncJobsBox.add(job);
    
    debugPrint('[SyncService] Added sync job: $collection/$docId ($action)');
    
    // Trigger sync immediately if online
    syncPendingJobs();
  }
}
