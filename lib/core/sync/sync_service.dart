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
          'userId': data['userId'] ?? '',
          'deviceId': deviceId,
          'exerciseId': data['exerciseId'] ?? '',
          'timestamp': Timestamp.fromDate(
            DateTime.parse(data['timestamp'] as String? ?? DateTime.now().toIso8601String())
          ),
          'weight': set['weight'] ?? 0.0,
          'reps': set['reps'] ?? 0,
          'setNumber': i + 1,
          'dropWeightKg': set['dropWeightKg'] ?? 0.0,
          'dropReps': set['dropReps'] ?? 0,
          'isBodyweight': set['isBodyweight'] ?? false,
          'note': data['note'],
        });
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
        
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
      }

      await batch.commit();
    }
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
