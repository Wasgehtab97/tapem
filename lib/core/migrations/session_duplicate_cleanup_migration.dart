import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapem/features/training_details/data/models/hive_session.dart';

/// One-time migration to clean up duplicate sessions created on 2025-11-27
/// This migration will only run once and mark itself as completed.
class SessionDuplicateCleanupMigration {
  static const String _migrationKey = 'migration_session_duplicate_cleanup_v1';
  
  /// Checks if this migration has already been executed
  static Future<bool> hasRun() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_migrationKey) ?? false;
  }
  
  /// Marks this migration as completed
  static Future<void> _markAsCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_migrationKey, true);
  }
  
  /// Runs the migration to clean up duplicate sessions
  /// Only processes sessions from 2025-11-27
  static Future<Map<String, dynamic>> run() async {
    debugPrint('🧹 Starting duplicate cleanup migration...');
    
    // Check if already run
    if (await hasRun()) {
      debugPrint('⏭️  Migration already completed, skipping');
      return {
        'skipped': true,
        'reason': 'already_run',
      };
    }
    
    try {
      final box = Hive.box<HiveSession>('sessions');
      
      // Filter sessions from 2025-11-27
      final targetDate = DateTime(2025, 11, 27);
      final endDate = DateTime(2025, 11, 28);
      
      final targetSessions = box.values.where((session) {
        return session.timestamp.isAfter(targetDate) && 
               session.timestamp.isBefore(endDate);
      }).toList();
      
      debugPrint('📊 Found ${targetSessions.length} sessions from 2025-11-27');
      
      // Group by sessionId
      final Map<String, List<HiveSession>> grouped = {};
      for (final session in targetSessions) {
        grouped.putIfAbsent(session.sessionId, () => []).add(session);
      }
      
      // Find duplicates
      var totalDuplicates = 0;
      var deletedCount = 0;
      final duplicateGroups = <String, int>{};
      
      for (final entry in grouped.entries) {
        final sessions = entry.value;
        if (sessions.length <= 1) continue;
        
        duplicateGroups[entry.key] = sessions.length;
        totalDuplicates += sessions.length - 1;
        
        // Sort by updatedAt (keep the most recent)
        sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        
        // Keep the first (most recent), delete the rest
        final toKeep = sessions.first;
        final toDelete = sessions.skip(1).toList();
        
        debugPrint('🔍 Session ${entry.key}:');
        debugPrint('   Total: ${sessions.length} (keeping most recent)');
        debugPrint('   Keep: Hive key ${toKeep.key} (updated: ${toKeep.updatedAt})');
        
        for (final duplicate in toDelete) {
          try {
            await duplicate.delete();
            deletedCount++;
            debugPrint('   ❌ Deleted: Hive key ${duplicate.key} (updated: ${duplicate.updatedAt})');
          } catch (e) {
            debugPrint('   ⚠️  Failed to delete: $e');
          }
        }
      }
      
      // Mark migration as completed
      await _markAsCompleted();
      
      final result = {
        'success': true,
        'targetDate': '2025-11-27',
        'totalSessionsScanned': targetSessions.length,
        'uniqueSessions': grouped.length,
        'duplicateGroupsFound': duplicateGroups.length,
        'totalDuplicates': totalDuplicates,
        'deletedCount': deletedCount,
        'duplicateGroups': duplicateGroups,
      };
      
      debugPrint('✅ Migration completed:');
      debugPrint('   Scanned: ${result['totalSessionsScanned']} sessions');
      debugPrint('   Unique: ${result['uniqueSessions']} sessions');
      debugPrint('   Duplicate groups: ${result['duplicateGroupsFound']}');
      debugPrint('   Deleted: $deletedCount duplicates');
      
      return result;
    } catch (e, st) {
      debugPrint('❌ Migration failed: $e');
      debugPrintStack(stackTrace: st);
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Gets statistics about duplicate sessions without deleting them
  static Future<Map<String, dynamic>> analyze() async {
    try {
      final box = Hive.box<HiveSession>('sessions');
      
      // Filter sessions from 2025-11-27
      final targetDate = DateTime(2025, 11, 27);
      final endDate = DateTime(2025, 11, 28);
      
      final targetSessions = box.values.where((session) {
        return session.timestamp.isAfter(targetDate) && 
               session.timestamp.isBefore(endDate);
      }).toList();
      
      // Group by sessionId
      final Map<String, List<HiveSession>> grouped = {};
      for (final session in targetSessions) {
        grouped.putIfAbsent(session.sessionId, () => []).add(session);
      }
      
      final duplicateGroups = grouped.entries
          .where((entry) => entry.value.length > 1)
          .toList();
      
      final totalDuplicates = duplicateGroups.fold<int>(
        0,
        (sum, entry) => sum + (entry.value.length - 1),
      );
      
      return {
        'targetDate': '2025-11-27',
        'totalSessions': targetSessions.length,
        'uniqueSessions': grouped.length,
        'duplicateGroups': duplicateGroups.length,
        'totalDuplicates': totalDuplicates,
        'wouldDelete': totalDuplicates,
      };
    } catch (e) {
      return {
        'error': e.toString(),
      };
    }
  }
}
