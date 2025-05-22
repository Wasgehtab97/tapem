import 'package:cloud_firestore/cloud_firestore.dart';
import '../dtos/device_dto.dart';

class FirestoreDeviceSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<DeviceDto>> getDevicesForGym(String gymId) async {
    final snap = await _firestore
      .collection('gyms')
      .doc(gymId)
      .collection('devices')
      .orderBy('name')
      .get();

    return snap.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      data['id'] = doc.id;
      data['nfcCode'] = data['nfcCode'] as String?;
      return DeviceDto.fromJson(data);
    }).toList();
  }

  Future<void> createDevice(String gymId, DeviceDto dto) async {
    await _firestore
      .collection('gyms')
      .doc(gymId)
      .collection('devices')
      .doc(dto.id)
      .set({
        'name': dto.name,
        'description': dto.description,
        'nfcCode': dto.nfcCode,
      });
  }
}
