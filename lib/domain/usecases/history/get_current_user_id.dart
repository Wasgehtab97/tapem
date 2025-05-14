// lib/domain/usecases/history/get_current_user_id.dart

import 'package:tapem/domain/repositories/history_repository.dart';

/// Liest die aktuelle User-ID aus dem History-Context.
///
/// Rückgabe: Aktuelle User-ID oder `null`, wenn keine vorhanden.
class GetCurrentUserIdHistoryUseCase {
  final HistoryRepository _repository;

  GetCurrentUserIdHistoryUseCase(this._repository);

  Future<String?> call() async {
    return await _repository.getCurrentUserId();
  }
}
