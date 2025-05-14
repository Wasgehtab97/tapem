import 'package:tapem/domain/models/client_info.dart';
import 'package:tapem/domain/repositories/coach_repository.dart';
import 'package:tapem/data/sources/coach/firestore_coach_source.dart';


class CoachRepositoryImpl implements CoachRepository {
  final FirestoreCoachSource _source;
  CoachRepositoryImpl({FirestoreCoachSource? source})
      : _source = source ?? FirestoreCoachSource();

  @override
  Future<List<ClientInfo>> loadClients(String coachId) async {
    final docs = await _source.loadClients(coachId);
    return docs.map((doc) {
      return ClientInfo.fromMap(
        doc.data(),
        id: doc.id,
      );
    }).toList();
  }

  @override
  Future<List<String>> fetchTrainingDates(String clientId) async {
    final docs = await _source.fetchTrainingDates(clientId);
    return docs.map((doc) => doc.data()['date'] as String).toList();
  }

  @override
  Future<void> sendCoachingRequest(
    String coachId,
    String membershipNumber,
  ) =>
      _source.sendCoachingRequest(coachId, membershipNumber);
}
