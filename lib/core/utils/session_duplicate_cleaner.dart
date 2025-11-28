import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tapem/features/training_details/data/models/hive_session.dart';

/// Utility script to clean up duplicate sessions from Hive database
/// This should be run once after deploying the fix
class SessionDuplicateCleaner {
  /// Removes duplicate sessions from the Hive sessions box
  /// Keeps only the latest version of each session (by sessionId)
  static Future<int> cleanDuplicates() async {
    final box = Hive.box<HiveSession>('sessions');
    
    // Group sessions by sessionId
    final Map<String, List<HiveSession>> grouped = {};
    for (final session in box.values) {
      grouped.putIfAbsent(session.sessionId, () => []).add(session);
    }
    
    // Find and remove duplicates
    int deletedCount = 0;
    for (final entry in grouped.entries) {
      final sessions = entry.value;
      if (sessions.length <= 1) continue; // No duplicates
      
      // Sort by updatedAt (keep the most recent)
      sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      
      // Keep the first (most recent), delete the rest
      final toKeep = sessions.first;
      final toDelete = sessions.skip(1).toList();
      
      debugPrint('🧹 Cleaning duplicates for session ${entry.key}:');
      debugPrint('   Found: ${sessions.length} duplicates');
      debugPrint('   Keeping: ${toKeep.key} (updated: ${toKeep.updatedAt})');
      
      for (final duplicate in toDelete) {
        await duplicate.delete();
        deletedCount++;
        debugPrint('   Deleted: ${duplicate.key} (updated: ${duplicate.updatedAt})');
      }
    }
    
    debugPrint('✅ Cleanup complete: $deletedCount duplicate sessions removed');
    return deletedCount;
  }
  
  /// Returns statistics about the current state of the database
  static Map<String, dynamic> getDatabaseStats() {
    final box = Hive.box<HiveSession>('sessions');
    
    // Group sessions by sessionId
    final Map<String, List<HiveSession>> grouped = {};
    for (final session in box.values) {
      grouped.putIfAbsent(session.sessionId, () => []).add(session);
    }
    
    final totalSessions = box.length;
    final uniqueSessions = grouped.length;
    final duplicateSessions = totalSessions - uniqueSessions;
    final duplicateGroups = grouped.values.where((list) => list.length > 1).length;
    
    return {
      'totalSessions': totalSessions,
      'uniqueSessions': uniqueSessions,
      'duplicateSessions': duplicateSessions,
      'duplicateGroups': duplicateGroups,
    };
  }
}
