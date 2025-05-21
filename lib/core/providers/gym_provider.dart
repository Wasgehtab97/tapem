// lib/core/providers/gym_provider.dart
import 'package:flutter/foundation.dart';
import 'package:tapem/features/gym/data/sources/firestore_gym_source.dart';
import 'package:tapem/features/gym/data/repositories/gym_repository_impl.dart';
import 'package:tapem/features/gym/domain/usecases/validate_gym_code.dart';
import 'package:tapem/features/gym/domain/models/gym_config.dart';
import 'package:tapem/features/device/data/sources/firestore_device_source.dart';
import 'package:tapem/features/device/data/repositories/device_repository_impl.dart';
import 'package:tapem/features/device/domain/usecases/get_devices_for_gym.dart';
import 'package:tapem/features/device/domain/models/device.dart';

/// Lädt Gym-Details und zugehörige Geräte für einen validierten Gym-Code.
class GymProvider extends ChangeNotifier {
  GymConfig? _gym;
  List<Device> _devices = [];
  bool _isLoading = false;
  String? _error;

  GymConfig? get gym => _gym;
  List<Device> get devices => _devices;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Validiert [gymCode], lädt die GymConfig und anschließend alle Geräte.
  Future<void> loadGymData(String gymCode) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // GymConfig validieren und laden
      final gymRepo = GymRepositoryImpl(FirestoreGymSource());
      _gym = await ValidateGymCode(gymRepo).execute(gymCode);

      // Geräte zu diesem Gym laden
      final deviceRepo =
          DeviceRepositoryImpl(FirestoreDeviceSource());
      _devices = await GetDevicesForGym(deviceRepo).execute(_gym!.id);
    } catch (e, st) {
      _error = 'Fehler beim Laden: ${e.toString()}';
      debugPrintStack(label: 'GymProvider.loadGymData', stackTrace: st);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
