// lib/domain/repositories/rank_repository.dart

import '../models/user_data.dart';

/// Schnittstelle für Ranglisten-Feature.
abstract class RankRepository {
  /// Holt alle Nutzerdaten für den Rang.
  Future<List<UserData>> fetchAllUsers();
}
