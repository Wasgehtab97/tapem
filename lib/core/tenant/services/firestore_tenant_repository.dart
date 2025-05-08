// lib/core/tenant/services/firestore_tenant_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../interfaces/tenant_repository.dart';
import '../../models/dto/gym_config_dto.dart';

/// Lädt GymConfigDto aus Firestore unter "gyms/{gymId}".
class FirestoreTenantRepository implements TenantRepository {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;

  @override
  Future<GymConfigDto> fetchConfig(String gymId) async {
    final doc = await _fs.collection('gyms').doc(gymId).get();
    if (!doc.exists || doc.data() == null) {
      throw Exception('GymConfig für $gymId nicht gefunden');
    }
    return GymConfigDto.fromJson(doc.data()!);
  }
}
