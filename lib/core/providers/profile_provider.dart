// lib/core/providers/profile_provider.dart
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/gym_provider.dart';
import 'package:tapem/features/history/data/repositories/history_repository_impl.dart';
import 'package:tapem/features/history/data/sources/firestore_history_source.dart';
import 'package:tapem/features/history/domain/models/workout_log.dart';
import 'package:tapem/features/history/domain/usecases/get_history_for_device.dart';

class ProfileProvider extends ChangeNotifier {
  final GetHistoryForDevice _getHistory = GetHistoryForDevice(
    HistoryRepositoryImpl(FirestoreHistorySource()),
  );

  bool _isLoading = false;
  String? _error;
  List<String> _trainingDates = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<String> get trainingDates => List.unmodifiable(_trainingDates);

  /// Lädt alle Trainingstage (YYYY-MM-DD) des aktuellen Users für alle Geräte.
  Future<void> loadTrainingDates(BuildContext context) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final gymId = auth.gymCode;
      final userId = auth.userId;
      final devices = Provider.of<GymProvider>(context, listen: false).devices;
      if (gymId == null || userId == null) {
        throw Exception('Kein Benutzer/Gym gefunden');
      }

      final datesSet = <String>{};
      for (final d in devices) {
        final logs = await _getHistory.execute(gymId, d.id, userId);
        for (final log in logs) {
          final dt = log.timestamp;
          final key =
              '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
          datesSet.add(key);
        }
      }
      _trainingDates = datesSet.toList();
    } catch (e, st) {
      _error = e.toString();
      debugPrintStack(
          label: 'ProfileProvider.loadTrainingDates', stackTrace: st);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
