import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/core/database/database_service.dart';
import 'package:tapem/core/sync/sync_service.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  throw UnimplementedError('databaseServiceProvider must be overridden in main.dart');
});

final syncServiceProvider = Provider<SyncService>((ref) {
  throw UnimplementedError('syncServiceProvider must be overridden in main.dart');
});
