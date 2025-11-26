import 'package:hive/hive.dart';

part 'hive_sync_job.g.dart';

/// Hive model for offline sync queue
@HiveType(typeId: 2)
class HiveSyncJob extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String collection;

  @HiveField(2)
  late String docId;

  @HiveField(3)
  late String action; // 'create', 'update', 'delete'

  @HiveField(4)
  late String payload; // JSON-encoded data

  @HiveField(5)
  late DateTime createdAt;

  @HiveField(6)
  late int retryCount;

  @HiveField(7)
  DateTime? lastAttempt;

  HiveSyncJob();
}
