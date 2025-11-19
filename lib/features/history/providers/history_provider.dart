// lib/features/history/providers/history_provider.dart

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/providers/gym_scoped_resettable.dart';
import 'package:tapem/features/history/data/repositories/history_repository_impl.dart';
import 'package:tapem/features/history/data/sources/firestore_history_source.dart';
import 'package:tapem/features/history/domain/models/workout_log.dart';
import 'package:tapem/features/history/domain/usecases/get_history_for_device.dart';
import 'package:tapem/core/providers/firebase_provider.dart';

class ChartPoint {
  final DateTime date;
  final double value;
  ChartPoint(this.date, this.value);
}

class HistoryProvider extends ChangeNotifier
    with GymScopedResettableChangeNotifier {
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
  double _maxE1rm = 0;
  List<ChartPoint> _e1rmChart = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<WorkoutLog> get logs => List.unmodifiable(_logs);
  int get workoutCount => _workoutCount;
  double get setsPerSessionAvg => _setsPerSessionAvg;
  double get heaviest => _heaviest;
  double get maxE1rm => _maxE1rm;
  List<ChartPoint> get e1rmChart => List.unmodifiable(_e1rmChart);

  /// Lädt die Historie für [deviceId] und den aktuell eingeloggten User.
  Future<void> loadHistory({
    required String gymId,
    required String deviceId,
    required String userId,
    String? exerciseId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
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
    final logsSorted = [..._logs]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    if (logsSorted.isEmpty) {
      _workoutCount = 0;
      _setsPerSessionAvg = 0;
      _heaviest = 0;
      _maxE1rm = 0;
      _e1rmChart = [];
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
          .toStringAsFixed(1),
    );
    _heaviest =
        logsSorted.map((e) => e.weight).reduce((a, b) => a > b ? a : b);

    _e1rmChart = sessionEntries.map((e) {
      final date = e.value.first.timestamp;
      final e1rm = e.value
          .map((l) => l.weight * (1 + l.reps / 30))
          .reduce((a, b) => a > b ? a : b);
      return ChartPoint(date, e1rm);
    }).toList();

    _maxE1rm =
        _e1rmChart.map((e) => e.value).reduce((a, b) => a > b ? a : b);
  }

  @override
  void resetGymScopedState() {
    _logs = [];
    _workoutCount = 0;
    _setsPerSessionAvg = 0;
    _heaviest = 0;
    _maxE1rm = 0;
    _e1rmChart = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    disposeGymScopedRegistration();
    super.dispose();
  }
}

final getHistoryForDeviceProvider = Provider<GetHistoryForDevice>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return GetHistoryForDevice(
    HistoryRepositoryImpl(FirestoreHistorySource(firestore)),
  );
});

final historyProvider = ChangeNotifierProvider<HistoryProvider>((ref) {
  final provider = HistoryProvider(
    getHistory: ref.watch(getHistoryForDeviceProvider),
  );
  final gymScopedController = ref.watch(gymScopedStateControllerProvider);
  provider.registerGymScopedResettable(gymScopedController);

  ref.listen<AuthViewState>(
    authViewStateProvider,
    (previous, next) {
      final gymChanged = previous?.gymCode != next.gymCode;
      final userChanged = previous?.userId != next.userId;
      if (!gymChanged && !userChanged) {
        if (!next.isLoggedIn || next.gymCode == null || next.userId == null) {
          provider.resetGymScopedState();
        }
        return;
      }
      provider.resetGymScopedState();
    },
    fireImmediately: true,
  );

  ref.onDispose(provider.dispose);
  return provider;
});
