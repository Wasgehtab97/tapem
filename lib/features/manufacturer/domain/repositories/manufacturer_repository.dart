import 'package:tapem/features/manufacturer/domain/models/manufacturer.dart';

abstract class ManufacturerRepository {
  /// Fetches all available global manufacturers (e.g., from 'manufacturers' collection).
  Future<List<Manufacturer>> getGlobalManufacturers();

  /// Fetches manufacturers specific to a gym (e.g., from 'gyms/{gymId}/manufacturers').
  Future<List<Manufacturer>> getGymManufacturers(String gymId);

  /// Adds a manufacturer (from global or custom) to a gym's list.
  Future<void> addManufacturerToGym(String gymId, Manufacturer manufacturer);

  /// Removes a manufacturer from a gym's list.
  Future<void> removeManufacturerFromGym(String gymId, String manufacturerId);

  /// Seeds the initial list of global manufacturers if they don't exist.
  Future<void> seedGlobalManufacturers();
}
