// lib/core/providers/gym_provider.dart

import 'package:flutter/foundation.dart';
import 'package:tapem/core/providers/gym_scoped_resettable.dart';
import 'package:tapem/features/device/data/repositories/device_repository_impl.dart';
import 'package:tapem/features/device/data/sources/firestore_device_source.dart';
import 'package:tapem/features/device/domain/models/device.dart';
import 'package:tapem/features/device/domain/usecases/get_devices_for_gym.dart';
import 'package:tapem/features/gym/data/repositories/gym_repository_impl.dart';
import 'package:tapem/features/gym/data/sources/firestore_gym_source.dart';
import 'package:tapem/features/gym/domain/models/gym_config.dart';
import 'package:tapem/features/gym/domain/usecases/get_gym_by_id.dart';

/// Lädt Gym-Details und zugehörige Geräte für eine Gym-ID.
class GymProvider extends ChangeNotifier
    with GymScopedResettableChangeNotifier {
  GymProvider({
    GetGymById? getGymById,
    GetDevicesForGym? getDevicesForGym,
  })  : _getGymById =
            getGymById ?? GetGymById(GymRepositoryImpl(FirestoreGymSource())),
        _getDevicesForGym = getDevicesForGym ??
            GetDevicesForGym(
              DeviceRepositoryImpl(FirestoreDeviceSource()),
            );

  GymConfig? _gym;
  List<Device> _devices = [];
  bool _isLoading = false;
  String? _error;
  String? _lastRequestedGymId;

  final GetGymById _getGymById;
  final GetDevicesForGym _getDevicesForGym;

  GymConfig? get gym => _gym;
  List<Device> get devices => _devices;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get lastRequestedGymId => _lastRequestedGymId;

  /// Document-ID des Gyms für Queries (leer, bis loadGymData aufgerufen wurde)
  String get currentGymId => _gym?.id ?? '';

  /// Lädt die GymConfig für die angegebene Gym-ID und dazu gehörige Geräte.
  Future<void> loadGymData(String gymId) async {
    _lastRequestedGymId = gymId;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _gym = await _getGymById.execute(gymId);
      _devices = await _getDevicesForGym.execute(_gym!.id);
    } catch (e, st) {
      _error = 'Fehler beim Laden: ${e.toString()}';
      debugPrintStack(label: 'GymProvider.loadGymData', stackTrace: st);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void resetGymScopedState() {
    _gym = null;
    _devices = [];
    _isLoading = false;
    _error = null;
    _lastRequestedGymId = null;
    notifyListeners();
  }

  void patchDeviceGroups(
    String deviceId,
    List<String> primaryGroups,
    List<String> secondaryGroups,
  ) {
    final i = _devices.indexWhere((d) => d.uid == deviceId);
    if (i == -1) return;
    _devices[i] = _devices[i].copyWith(
      primaryMuscleGroups: primaryGroups,
      secondaryMuscleGroups: secondaryGroups,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    disposeGymScopedRegistration();
    super.dispose();
  }
}
