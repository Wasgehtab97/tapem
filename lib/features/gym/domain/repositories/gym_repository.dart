// lib/features/gym/domain/repositories/gym_repository.dart
import '../models/gym_config.dart';

abstract class GymRepository {
  /// Liefert das GymConfig-Objekt zum [code] oder null, wenn nicht gefunden.
  Future<GymConfig?> getGymByCode(String code);

  /// Gibt das GymConfig-Objekt zur Dokument-ID oder null zurück.
  Future<GymConfig?> getGymById(String id);
}
