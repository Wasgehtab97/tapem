import 'package:isar/isar.dart';

part 'sync_job.g.dart';

@collection
class SyncJob {
  Id id = Isar.autoIncrement;

  @Index()
  late String collection; // 'sessions', 'users', etc.

  @Index()
  late String docId;

  @Index()
  late String action; // 'create', 'update', 'delete'

  late String payload; // JSON string of the data

  late DateTime createdAt;

  late int retryCount;

  @Index()
  late DateTime? lastAttempt;
}
