import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/core/providers/database_provider.dart';
import 'package:tapem/core/providers/firebase_provider.dart';
import 'package:tapem/features/training_details/data/repositories/session_repository_impl.dart';
import 'package:tapem/features/training_details/data/session_meta_source.dart';
import 'package:tapem/features/training_details/domain/repositories/session_repository.dart';

final sessionMetaSourceProvider = Provider<SessionMetaSource>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return SessionMetaSource(firestore: firestore);
});

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  final syncService = ref.watch(syncServiceProvider);
  final metaSource = ref.watch(sessionMetaSourceProvider);
  
  return SessionRepositoryImpl(
    databaseService,
    syncService,
    metaSource,
  );
});
