import 'package:flutter/foundation.dart';
import 'package:tapem/features/device/domain/models/exercise.dart';
import 'package:tapem/features/device/domain/usecases/get_exercises_for_device.dart';

class AllExercisesProvider extends ChangeNotifier {
  final GetExercisesForDevice _getEx;
  AllExercisesProvider({required GetExercisesForDevice getEx}) : _getEx = getEx;

  final Map<String, List<Exercise>> _byDevice = {};
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, List<Exercise>> get byDevice => Map.unmodifiable(_byDevice);

  List<MapEntry<String, Exercise>> get allExercises => [
    for (final entry in _byDevice.entries)
      for (final ex in entry.value) MapEntry(entry.key, ex),
  ];

  Future<void> loadAll(
    String gymId,
    List<String> deviceIds,
    String userId,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final tmp = <String, List<Exercise>>{};
    try {
      for (final dId in deviceIds) {
        final ex = await _getEx.execute(gymId, dId, userId);
        tmp[dId] = ex;
      }
      _byDevice
        ..clear()
        ..addAll(tmp);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
