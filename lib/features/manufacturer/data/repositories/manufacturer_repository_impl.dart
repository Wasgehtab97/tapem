import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tapem/features/manufacturer/domain/models/manufacturer.dart';
import 'package:tapem/features/manufacturer/domain/repositories/manufacturer_repository.dart';

class ManufacturerRepositoryImpl implements ManufacturerRepository {
  final FirebaseFirestore _firestore;

  ManufacturerRepositoryImpl(this._firestore);

  CollectionReference<Map<String, dynamic>> get _globalRef =>
      _firestore.collection('manufacturers');

  CollectionReference<Map<String, dynamic>> _gymRef(String gymId) =>
      _firestore.collection('gyms').doc(gymId).collection('manufacturers');

  @override
  Future<List<Manufacturer>> getGlobalManufacturers() async {
    final query = await _globalRef.get();
    return query.docs.map((e) => Manufacturer.fromJson(e.data())).toList();
  }

  @override
  Future<List<Manufacturer>> getGymManufacturers(String gymId) async {
    final query = await _gymRef(gymId).get();
    return query.docs.map((e) => Manufacturer.fromJson(e.data())).toList();
  }

  @override
  Future<void> addManufacturerToGym(String gymId, Manufacturer manufacturer) async {
    // When adding to gym, we ensure the ID is consistent.
    // We store the full object to avoid joins and allow gym-specific customization later.
    final docRef = _gymRef(gymId).doc(manufacturer.id);
    // Use set with merge true to avoiding overwriting custom fields if we update base info.
    await docRef.set(manufacturer.toJson(), SetOptions(merge: true));
  }

  @override
  Future<void> removeManufacturerFromGym(String gymId, String manufacturerId) async {
    await _gymRef(gymId).doc(manufacturerId).delete();
  }

  @override
  Future<void> seedGlobalManufacturers() async {
    final initialList = [
      'Rogue', 'Cybex', 'Gymleco', 'Matrix', 'Schnell', 'Hoist', 
      'Hammer Strength', 'gym80', 'ATX', 'Panatta', 'Precor', 
      'Booty Builder', 'Eleiko', 'Nautilus', 'Strive'
    ];

    final batch = _firestore.batch();
    
    // Check if we already have data to avoid unnecessary writes? 
    // Or just write/update to ensure consistency. 
    // Let's just update existing ones or create new ones.
    
    for (final name in initialList) {
      // Create a slug/id from name (e.g. "Hammer Strength" -> "hammer_strength")
      final id = name.toLowerCase().replaceAll(' ', '_');
      final docRef = _globalRef.doc(id);
      
      final manufacturer = Manufacturer(
        id: id,
        name: name,
        isGlobal: true,
      );
      
      batch.set(docRef, manufacturer.toJson(), SetOptions(merge: true));
    }

    await batch.commit();
  }
}
