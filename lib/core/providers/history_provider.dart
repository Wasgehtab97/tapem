// lib/core/providers/history_provider.dart
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/features/history/data/repositories/history_repository_impl.dart';
import 'package:tapem/features/history/data/sources/firestore_history_source.dart';
import 'package:tapem/features/history/domain/models/workout_log.dart';
import 'package:tapem/features/history/domain/usecases/get_history_for_device.dart';

class HistoryProvider extends ChangeNotifier {
  final GetHistoryForDevice _getHistory;

  HistoryProvider()
      : _getHistory = GetHistoryForDevice(
          HistoryRepositoryImpl(FirestoreHistorySource()),
        );

  bool _isLoading = false;
  String? _error;
  List<WorkoutLog> _logs = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<WorkoutLog> get logs => List.unmodifiable(_logs);

  /// Lädt die Historie für [deviceId] und den aktuell eingeloggten User.
  Future<void> loadHistory(BuildContext context, String deviceId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final gymId = auth.gymCode;
      final userId = auth.userId;
      if (gymId == null || userId == null) {
        throw Exception('Benutzer nicht eingeloggt');
      }
      _logs = await _getHistory.execute(gymId, deviceId, userId);
    } catch (e, st) {
      _error = 'Fehler beim Laden: ${e.toString()}';
      debugPrintStack(label: 'HistoryProvider.loadHistory', stackTrace: st);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
