// lib/domain/usecases/report/fetch_feedback_status.dart

import 'package:tapem/domain/repositories/report_repository.dart';

/// Use-Case: Holt den Feedback-Status für alle Geräte eines Gyms.
/// 
/// - [gymId]: ID des Gyms.
/// - Rückgabe: Map von Geräte-ID zu Status-String.
class FetchFeedbackStatusUseCase {
  final ReportRepository _repository;

  FetchFeedbackStatusUseCase(this._repository);

  Future<Map<String, String>> call(String gymId) async {
    return await _repository.fetchFeedbackStatus(gymId);
  }
}
