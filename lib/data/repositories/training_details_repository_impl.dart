import 'package:tapem/domain/repositories/training_details_repository.dart';
import 'package:tapem/data/sources/training_details/firestore_training_details_source.dart';


/// Firestore-Implementierung von [TrainingDetailsRepository].
class TrainingDetailsRepositoryImpl
    implements TrainingDetailsRepository {
  final FirestoreTrainingDetailsSource _source;
  TrainingDetailsRepositoryImpl({FirestoreTrainingDetailsSource? source})
      : _source = source ?? FirestoreTrainingDetailsSource();

  @override
  Future<String?> getCurrentUserId() {
    return _source.getCurrentUserId();
  }

  @override
  Future<List<Map<String, dynamic>>> fetchDetailsForDate({
    required String userId,
    required String dateKey,
  }) {
    return _source.fetchDetailsForDate(userId: userId, dateKey: dateKey);
  }
}
