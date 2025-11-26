import 'package:hive_flutter/hive_flutter.dart';
import 'package:tapem/features/training_details/data/models/hive_session.dart';
import 'package:tapem/core/sync/models/hive_sync_job.dart';

/// Database service using Hive for local storage
class DatabaseService {
  static const String _sessionsBoxName = 'sessions';
  static const String _syncJobsBoxName = 'sync_jobs';

  late Box<HiveSession> _sessionsBox;
  late Box<HiveSyncJob> _syncJobsBox;

  /// Get sessions box
  Box<HiveSession> get sessionsBox => _sessionsBox;

  /// Get sync jobs box
  Box<HiveSyncJob> get syncJobsBox => _syncJobsBox;

  Future<void> init() async {
    // Initialize Hive
    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(HiveSessionAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(HiveSessionSetAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(HiveSyncJobAdapter());
    }

    // Open boxes
    _sessionsBox = await Hive.openBox<HiveSession>(_sessionsBoxName);
    _syncJobsBox = await Hive.openBox<HiveSyncJob>(_syncJobsBoxName);

    print('[DatabaseService] Hive initialized successfully');
    print('[DatabaseService] Sessions: ${_sessionsBox.length}, Sync Jobs: ${_syncJobsBox.length}');
  }

  Future<void> clean() async {
    await _sessionsBox.clear();
    await _syncJobsBox.clear();
    print('[DatabaseService] All data cleared');
  }

  /// Close all boxes (call on app disposal)
  Future<void> close() async {
    await _sessionsBox.close();
    await _syncJobsBox.close();
  }
}
