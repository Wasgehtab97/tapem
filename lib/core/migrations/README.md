# Database Migrations

This directory contains one-time database migrations that run automatically on app startup.

## Current Migrations

### SessionDuplicateCleanupMigration (v1)

**Purpose:** Clean up duplicate sessions created on 2025-11-27 due to a bug in `SessionRepositoryImpl.syncFromRemote()`.

**Target Date:** 2025-11-27  
**Status:** Active  
**Location:** [`session_duplicate_cleanup_migration.dart`](file:///Users/daniel/Projekte/tapem/lib/core/migrations/session_duplicate_cleanup_migration.dart)

**What it does:**
1. Checks if the migration has already run (stored in SharedPreferences)
2. If not, scans all sessions from 2025-11-27
3. Groups sessions by `sessionId`
4. For each group with duplicates:
   - Keeps the most recently updated session
   - Deletes all older duplicates
5. Marks the migration as completed

**How to verify:**
The migration logs detailed information to the console:
```
🧹 Starting duplicate cleanup migration...
📊 Found X sessions from 2025-11-27
🔍 Session {sessionId}:
   Total: 3 (keeping most recent)
   Keep: Hive key 123 (updated: 2025-11-27...)
   ❌ Deleted: Hive key 124 (updated: 2025-11-27...)
   ❌ Deleted: Hive key 125 (updated: 2025-11-27...)
✅ Migration completed:
   Scanned: X sessions
   Unique: Y sessions
   Duplicate groups: Z
   Deleted: N duplicates
```

**Related Fix:**
The root cause was fixed in [`session_repository_impl.dart`](file:///Users/daniel/Projekte/tapem/lib/features/training_details/data/repositories/session_repository_impl.dart#L157-L253) by implementing upsert logic.

## How Migrations Work

1. Migrations are executed in [`bootstrap.dart`](file:///Users/daniel/Projekte/tapem/lib/bootstrap/bootstrap.dart) after database initialization
2. Each migration checks if it has already run using SharedPreferences
3. If already run, it skips execution
4. Migrations are designed to be idempotent and safe to run multiple times

## Adding New Migrations

1. Create a new file in this directory: `{description}_migration.dart`
2. Implement the migration class with:
   - `hasRun()` - Check if migration completed
   - `run()` - Execute the migration
   - `_markAsCompleted()` - Mark as done
3. Add the migration to `bootstrap.dart`
4. Test thoroughly before deploying!
