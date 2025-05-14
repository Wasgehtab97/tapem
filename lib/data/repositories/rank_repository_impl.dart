import 'package:tapem/domain/models/user_data.dart';
import 'package:tapem/domain/repositories/rank_repository.dart';
import 'package:tapem/data/sources/rank/firestore_rank_source.dart';


/// Firestore-Implementierung von [RankRepository].
class RankRepositoryImpl implements RankRepository {
  final FirestoreRankSource _source;
  RankRepositoryImpl({FirestoreRankSource? source})
      : _source = source ?? FirestoreRankSource();

  @override
  Future<List<UserData>> fetchAllUsers() {
    return _source.fetchAllUsers();
  }
}
