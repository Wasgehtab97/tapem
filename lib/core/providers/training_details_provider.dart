import 'package:flutter/foundation.dart';
import 'package:tapem/features/training_details/data/repositories/session_repository_impl.dart';
import 'package:tapem/features/training_details/data/sources/firestore_session_source.dart';
import 'package:tapem/features/training_details/data/session_meta_source.dart';
import 'package:tapem/features/training_details/domain/usecases/delete_session.dart';
import 'package:tapem/features/training_details/domain/usecases/get_sessions_for_date.dart';
import 'package:tapem/features/training_details/domain/models/session.dart';
import 'package:tapem/core/time/logic_day.dart';

/// Notifier für den TrainingDetailsScreen.
class TrainingDetailsProvider extends ChangeNotifier {
  late final GetSessionsForDate _getSessions;
  late final DeleteSession _deleteSession;
  final SessionMetaSource _meta = SessionMetaSource();
  String? _userId;
  String? _gymId;
  DateTime? _date;

  bool _isLoading = false;
  String? _error;
  List<Session> _sessions = [];
  int? _dayDurationMs;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Session> get sessions => List.unmodifiable(_sessions);
  int? get dayDurationMs => _dayDurationMs;

  TrainingDetailsProvider() {
    final repo = SessionRepositoryImpl(
      FirestoreSessionSource(),
      _meta,
    );
    _getSessions = GetSessionsForDate(repo);
    _deleteSession = DeleteSession(repo);
  }

  /// Lädt alle Sessions für [userId] am [date].
  Future<void> loadSessions({
    required String userId,
    required DateTime date,
    required String gymId,
  }) async {
    debugPrint('📆 loadSessions user=$userId date=$date gym=$gymId');
    _userId = userId;
    _gymId = gymId;
    _date = date;
    await _refreshSessions(showLoading: true);
  }

  Future<void> deleteSession(Session session) async {
    final userId = _userId;
    final gymId = _gymId;
    if (userId == null || gymId == null || _date == null) {
      throw StateError('TrainingDetailsProvider not initialised');
    }
    _isLoading = true;
    notifyListeners();
    try {
      await _deleteSession.execute(
        gymId: gymId,
        userId: userId,
        session: session,
      );
      await _refreshSessions(showLoading: false);
      if (_error != null) {
        throw Exception(_error);
      }
    } catch (e) {
      debugPrint('❌ deleteSession error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _refreshSessions({required bool showLoading}) async {
    final userId = _userId;
    final gymId = _gymId;
    final date = _date;
    if (userId == null || gymId == null || date == null) {
      return;
    }

    if (showLoading) {
      _isLoading = true;
      notifyListeners();
    }
    _error = null;

    try {
      _sessions = await _getSessions.execute(userId: userId, date: date);
      debugPrint('✅ loaded ${_sessions.length} sessions');
      if (_sessions.isNotEmpty) {
        _dayDurationMs = _sessions.first.durationMs;
      } else {
        final dayKey = logicDayKey(date);
        final meta = await _meta.getMetaByDayKey(
          gymId: gymId,
          uid: userId,
          dayKey: dayKey,
        );
        _dayDurationMs = (meta?['durationMs'] as num?)?.toInt();
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ loadSessions error: $e');
    }

    if (showLoading) {
      _isLoading = false;
    }
    notifyListeners();
  }
}
