// lib/core/providers/history_provider.dart

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/features/history/data/sources/firestore_history_source.dart';
import 'package:tapem/features/history/data/repositories/history_repository_impl.dart';
import 'package:tapem/features/history/domain/usecases/get_history_for_device.dart';
import 'package:tapem/features/history/domain/models/workout_log.dart';

class ChartPoint {
  final DateTime date;
  final double value;
  ChartPoint(this.date, this.value);
}

class HistoryProvider extends ChangeNotifier {
  final GetHistoryForDevice _getHistory;

  HistoryProvider({GetHistoryForDevice? getHistory})
    : _getHistory =
          getHistory ??
          GetHistoryForDevice(HistoryRepositoryImpl(FirestoreHistorySource()));

  bool _isLoading = false;
  String? _error;
  List<WorkoutLog> _logs = [];
  int _workoutCount = 0;
  double _setsPerSessionAvg = 0;
  double _heaviest = 0;
  List<ChartPoint> _e1rmChart = [];
  List<ChartPoint> _sessionsChart = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<WorkoutLog> get logs => List.unmodifiable(_logs);
  int get workoutCount => _workoutCount;
  double get setsPerSessionAvg => _setsPerSessionAvg;
  double get heaviest => _heaviest;
  List<ChartPoint> get e1rmChart => List.unmodifiable(_e1rmChart);
  List<ChartPoint> get sessionsChart => List.unmodifiable(_sessionsChart);

  /// Lädt die Historie für [deviceId] und den aktuell eingeloggten User.
  Future<void> loadHistory({
    required BuildContext context,
    required String deviceId,
    String? exerciseId,
  }) async {
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

      _logs = await _getHistory.execute(
        gymId: gymId,
        deviceId: deviceId,
        userId: userId,
        exerciseId: exerciseId,
      );
      _computeStats();
    } catch (e, st) {
      _error = 'Fehler beim Laden: ${e.toString()}';
      debugPrintStack(label: 'HistoryProvider.loadHistory', stackTrace: st);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _computeStats() {
    final logsSorted = [..._logs]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    if (logsSorted.isEmpty) {
      _workoutCount = 0;
      _setsPerSessionAvg = 0;
      _heaviest = 0;
      _e1rmChart = [];
      _sessionsChart = [];
      return;
    }

    final sessions = <String, List<WorkoutLog>>{};
    for (final log in logsSorted) {
      sessions.putIfAbsent(log.sessionId, () => []).add(log);
    }

    final sessionEntries = sessions.entries.toList()
      ..sort((a, b) =>
          a.value.first.timestamp.compareTo(b.value.first.timestamp));

    _workoutCount = sessionEntries.length;
    _setsPerSessionAvg = double.parse(
        (_logs.length / (_workoutCount == 0 ? 1 : _workoutCount))
            .toStringAsFixed(1));
    _heaviest = logsSorted.map((e) => e.weight).reduce((a, b) => a > b ? a : b);

    _e1rmChart = sessionEntries.map((e) {
      final date = e.value.first.timestamp;
      final e1rm = e.value
          .map((l) => l.weight * (1 + l.reps / 30))
          .reduce((a, b) => a > b ? a : b);
      return ChartPoint(date, e1rm);
    }).toList();

    final perDay = <DateTime, int>{};
    for (final entry in sessionEntries) {
      final day = DateTime(entry.value.first.timestamp.year,
          entry.value.first.timestamp.month, entry.value.first.timestamp.day);
      perDay.update(day, (v) => v + 1, ifAbsent: () => 1);
    }
    final sortedDays = perDay.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    var cumulative = 0;
    _sessionsChart = sortedDays.map((e) {
      cumulative += e.value;
      return ChartPoint(e.key, cumulative.toDouble());
    }).toList();
  }
}
