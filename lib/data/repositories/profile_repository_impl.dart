import 'package:tapem/domain/repositories/profile_repository.dart';
import 'package:tapem/data/sources/profile/firestore_profile_source.dart';


/// Firestore-Implementierung von [ProfileRepository].
class ProfileRepositoryImpl implements ProfileRepository {
  final FirestoreProfileSource _source;
  ProfileRepositoryImpl({FirestoreProfileSource? source})
      : _source = source ?? FirestoreProfileSource();

  @override
  Future<String?> getCurrentUserId() => _source.getCurrentUserId();

  @override
  Future<Map<String, dynamic>> fetchUserProfile(String userId) {
    return _source.fetchUserProfile(userId);
  }

  @override
  Future<List<String>> fetchTrainingDates(String userId) {
    return _source.fetchTrainingDates(userId);
  }

  @override
  Future<Map<String, dynamic>?> fetchPendingCoachingRequest(String userId) {
    return _source.fetchPendingCoachingRequest(userId);
  }

  @override
  Future<void> respondToCoachingRequest(String requestId, bool accept) {
    return _source.respondToCoachingRequest(requestId, accept);
  }

  @override
  Future<void> signOut() {
    return _source.signOut();
  }
}
