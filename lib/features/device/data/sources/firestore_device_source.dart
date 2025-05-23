// lib/features/device/data/sources/firestore_device_source.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/device.dart';

class FirestoreDeviceSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Device>> getDevicesForGym(String gymId) async {
    final snap = await _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('devices')
        .orderBy('name')
        .get();

    return snap.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      data['id'] = doc.id;
      return Device.fromJson(data);
    }).toList();
  }

  Future<void> createDevice(String gymId, Device device) async {
    await _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('devices')
        .doc(device.id)
        .set(device.toJson());
  }
}
