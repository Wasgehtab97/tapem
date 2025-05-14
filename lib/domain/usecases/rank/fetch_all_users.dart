// lib/domain/usecases/rank/fetch_all_users.dart

import 'package:tapem/domain/models/user_data.dart';
import 'package:tapem/domain/repositories/rank_repository.dart';

/// Holt alle Nutzerdaten für die Rangliste.
///
/// Rückgabe: Eine Liste von [UserData], sortiert nach Rang oder Punkten.
class FetchAllUsersUseCase {
  final RankRepository _repository;

  FetchAllUsersUseCase(this._repository);

  Future<List<UserData>> call() async {
    return await _repository.fetchAllUsers();
  }
}
