// lib/domain/usecases/training_details/get_current_user_id.dart

import 'package:tapem/domain/repositories/training_details_repository.dart';

/// Use-Case: Liest die aktuell angemeldete User-ID für Training Details.
///
/// Nützlich, um automatisch die Details für den eingeloggten Nutzer zu laden.
class GetCurrentUserIdDetailsUseCase {
  final TrainingDetailsRepository _repository;

  GetCurrentUserIdDetailsUseCase(this._repository);

  Future<String?> call() async {
    return await _repository.getCurrentUserId();
  }
}
