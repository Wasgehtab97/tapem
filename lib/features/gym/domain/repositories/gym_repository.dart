// lib/features/gym/domain/repositories/gym_repository.dart
import '../models/gym_config.dart';

abstract class GymRepository {
  /// Liefert das GymConfig-Objekt zum [code] oder null, wenn nicht gefunden.
  Future<GymConfig?> getGymByCode(String code);
}
