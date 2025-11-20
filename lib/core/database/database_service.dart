import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tapem/features/training_details/data/models/local_session.dart';
import 'package:tapem/core/sync/models/sync_job.dart';

class DatabaseService {
  late final Isar isar;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [LocalSessionSchema, SyncJobSchema],
      directory: dir.path,
    );
  }

  Future<void> clean() async {
    await isar.writeTxn(() async {
      await isar.clear();
    });
  }
}
