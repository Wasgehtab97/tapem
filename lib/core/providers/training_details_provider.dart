import 'package:flutter/foundation.dart';
import 'package:tapem/features/training_details/data/repositories/session_repository_impl.dart';
import 'package:tapem/features/training_details/data/sources/firestore_session_source.dart';
import 'package:tapem/features/training_details/data/session_meta_source.dart';
import 'package:tapem/features/training_details/domain/usecases/get_sessions_for_date.dart';
import 'package:tapem/features/training_details/domain/models/session.dart';

/// Notifier für den TrainingDetailsScreen.
class TrainingDetailsProvider extends ChangeNotifier {
  final GetSessionsForDate _getSessions;

  bool _isLoading = false;
  String? _error;
  List<Session> _sessions = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Session> get sessions => List.unmodifiable(_sessions);

  TrainingDetailsProvider()
    : _getSessions = GetSessionsForDate(
        SessionRepositoryImpl(
          FirestoreSessionSource(),
          SessionMetaSource(),
        ),
      );

  /// Lädt alle Sessions für [userId] am [date].
  Future<void> loadSessions({
    required String userId,
    required DateTime date,
  }) async {
    debugPrint('📆 loadSessions user=$userId date=$date');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _sessions = await _getSessions.execute(userId: userId, date: date);
      debugPrint('✅ loaded ${_sessions.length} sessions');
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ loadSessions error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
