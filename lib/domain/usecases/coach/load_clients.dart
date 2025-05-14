// lib/domain/usecases/coach/load_clients.dart

import 'package:tapem/domain/repositories/coach_repository.dart';
import 'package:tapem/domain/models/client_info.dart';

/// UseCase zum Laden aller Klienten für einen Coach.
///
/// Liefert eine Liste von [ClientInfo].
class LoadClientsUseCase {
  final CoachRepository _repository;

  LoadClientsUseCase(this._repository);

  /// [coachId] ist die eindeutige Kennung des Coaches.
  Future<List<ClientInfo>> call({ required String coachId }) async {
    return await _repository.loadClients(coachId);
  }
}
