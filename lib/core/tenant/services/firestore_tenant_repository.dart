import 'package:cloud_firestore/cloud_firestore.dart';
import '../interfaces/tenant_repository.dart';
import '../../models/dto/gym_config_dto.dart';

/// Firestore-Implementierung für TenantRepository.
/// Liest das Dokument unter "gyms/{gymId}" und mappt auf DTO.
class FirestoreTenantRepository implements TenantRepository {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;

  @override
  Future<GymConfigDto> fetchConfig(String gymId) async {
    final docRef = _fs.collection('gyms').doc(gymId);
    final snap = await docRef.get();

    if (!snap.exists || snap.data() == null) {
      throw StateError('GymConfig für "$gymId" nicht in Firestore gefunden.');
    }
    try {
      return GymConfigDto.fromJson(snap.data()!);
    } catch (e) {
      throw FormatException('Ungültiges GymConfig-Format: $e');
    }
  }
}
