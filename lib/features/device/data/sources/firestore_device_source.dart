import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/device.dart';

class FirestoreDeviceSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Device>> getDevicesForGym(String gymId) async {
    final snap = await _firestore
        .collection('gyms').doc(gymId)
        .collection('devices')
        .orderBy('name')
        .get();

    return snap.docs.map((doc) {
      final m = doc.data();
      m['id'] = doc.id;
      return Device.fromJson(m);
    }).toList();
  }

  Future<void> createDevice(String gymId, Device device) {
    return _firestore
      .collection('gyms').doc(gymId)
      .collection('devices').doc(device.id)
      .set(device.toJson());
  }
}
