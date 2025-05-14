// lib/domain/usecases/gym/fetch_devices.dart

import 'package:tapem/domain/models/device_model.dart';
import 'package:tapem/domain/repositories/gym_repository.dart';

/// Holt alle Geräte für die Gym-Übersicht.
/// 
/// [nameQuery] – Optionaler Suchbegriff zur Filterung nach Gerätenamen.
/// Rückgabe: Liste von [DeviceModel].
class FetchGymDevicesUseCase {
  final GymRepository _repository;

  FetchGymDevicesUseCase(this._repository);

  Future<List<DeviceModel>> call({String? nameQuery}) async {
    return await _repository.fetchDevices(nameQuery: nameQuery);
  }
}
